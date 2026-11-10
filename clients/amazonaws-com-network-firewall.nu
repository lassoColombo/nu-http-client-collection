# Auto-generated client for AWS Network Firewall v2020-11-12
# Source: https://api.apis.guru/v2/specs/amazonaws.com/network-firewall/2020-11-12/openapi.json
# Auth: --token flag or $env.AWS_NETWORK_FIREWALL_TOKEN

const BASE_URL = "http://network-firewall.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_NETWORK_FIREWALL_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://network-firewall.us-east-1.amazonaws.com" "http://network-firewall.us-east-2.amazonaws.com" "http://network-firewall.us-west-1.amazonaws.com" "http://network-firewall.us-west-2.amazonaws.com" "http://network-firewall.us-gov-west-1.amazonaws.com" "http://network-firewall.us-gov-east-1.amazonaws.com" "http://network-firewall.ca-central-1.amazonaws.com" "http://network-firewall.eu-north-1.amazonaws.com" "http://network-firewall.eu-west-1.amazonaws.com" "http://network-firewall.eu-west-2.amazonaws.com" "http://network-firewall.eu-west-3.amazonaws.com" "http://network-firewall.eu-central-1.amazonaws.com" "http://network-firewall.eu-south-1.amazonaws.com" "http://network-firewall.af-south-1.amazonaws.com" "http://network-firewall.ap-northeast-1.amazonaws.com" "http://network-firewall.ap-northeast-2.amazonaws.com" "http://network-firewall.ap-northeast-3.amazonaws.com" "http://network-firewall.ap-southeast-1.amazonaws.com" "http://network-firewall.ap-southeast-2.amazonaws.com" "http://network-firewall.ap-east-1.amazonaws.com" "http://network-firewall.ap-south-1.amazonaws.com" "http://network-firewall.sa-east-1.amazonaws.com" "http://network-firewall.me-south-1.amazonaws.com" "https://network-firewall.us-east-1.amazonaws.com" "https://network-firewall.us-east-2.amazonaws.com" "https://network-firewall.us-west-1.amazonaws.com" "https://network-firewall.us-west-2.amazonaws.com" "https://network-firewall.us-gov-west-1.amazonaws.com" "https://network-firewall.us-gov-east-1.amazonaws.com" "https://network-firewall.ca-central-1.amazonaws.com" "https://network-firewall.eu-north-1.amazonaws.com" "https://network-firewall.eu-west-1.amazonaws.com" "https://network-firewall.eu-west-2.amazonaws.com" "https://network-firewall.eu-west-3.amazonaws.com" "https://network-firewall.eu-central-1.amazonaws.com" "https://network-firewall.eu-south-1.amazonaws.com" "https://network-firewall.af-south-1.amazonaws.com" "https://network-firewall.ap-northeast-1.amazonaws.com" "https://network-firewall.ap-northeast-2.amazonaws.com" "https://network-firewall.ap-northeast-3.amazonaws.com" "https://network-firewall.ap-southeast-1.amazonaws.com" "https://network-firewall.ap-southeast-2.amazonaws.com" "https://network-firewall.ap-east-1.amazonaws.com" "https://network-firewall.ap-south-1.amazonaws.com" "https://network-firewall.sa-east-1.amazonaws.com" "https://network-firewall.me-south-1.amazonaws.com" "http://network-firewall.cn-north-1.amazonaws.com.cn" "http://network-firewall.cn-northwest-1.amazonaws.com.cn" "https://network-firewall.cn-north-1.amazonaws.com.cn" "https://network-firewall.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["NetworkFirewall_20201112.AssociateFirewallPolicy"] }
def x-amz-target-completer-1 [] { ["NetworkFirewall_20201112.AssociateSubnets"] }
def x-amz-target-completer-2 [] { ["NetworkFirewall_20201112.CreateFirewall"] }
def x-amz-target-completer-3 [] { ["NetworkFirewall_20201112.CreateFirewallPolicy"] }
def type-completer [] { ["STATEFUL" "STATELESS"] }
def x-amz-target-completer-4 [] { ["NetworkFirewall_20201112.CreateRuleGroup"] }
def x-amz-target-completer-5 [] { ["NetworkFirewall_20201112.CreateTLSInspectionConfiguration"] }
def x-amz-target-completer-6 [] { ["NetworkFirewall_20201112.DeleteFirewall"] }
def x-amz-target-completer-7 [] { ["NetworkFirewall_20201112.DeleteFirewallPolicy"] }
def x-amz-target-completer-8 [] { ["NetworkFirewall_20201112.DeleteResourcePolicy"] }
def x-amz-target-completer-9 [] { ["NetworkFirewall_20201112.DeleteRuleGroup"] }
def x-amz-target-completer-10 [] { ["NetworkFirewall_20201112.DeleteTLSInspectionConfiguration"] }
def x-amz-target-completer-11 [] { ["NetworkFirewall_20201112.DescribeFirewall"] }
def x-amz-target-completer-12 [] { ["NetworkFirewall_20201112.DescribeFirewallPolicy"] }
def x-amz-target-completer-13 [] { ["NetworkFirewall_20201112.DescribeLoggingConfiguration"] }
def x-amz-target-completer-14 [] { ["NetworkFirewall_20201112.DescribeResourcePolicy"] }
def x-amz-target-completer-15 [] { ["NetworkFirewall_20201112.DescribeRuleGroup"] }
def x-amz-target-completer-16 [] { ["NetworkFirewall_20201112.DescribeRuleGroupMetadata"] }
def x-amz-target-completer-17 [] { ["NetworkFirewall_20201112.DescribeTLSInspectionConfiguration"] }
def x-amz-target-completer-18 [] { ["NetworkFirewall_20201112.DisassociateSubnets"] }
def x-amz-target-completer-19 [] { ["NetworkFirewall_20201112.ListFirewallPolicies"] }
def x-amz-target-completer-20 [] { ["NetworkFirewall_20201112.ListFirewalls"] }
def scope-completer [] { ["ACCOUNT" "MANAGED"] }
def managed-type-completer [] { ["AWS_MANAGED_DOMAIN_LISTS" "AWS_MANAGED_THREAT_SIGNATURES"] }
def x-amz-target-completer-21 [] { ["NetworkFirewall_20201112.ListRuleGroups"] }
def x-amz-target-completer-22 [] { ["NetworkFirewall_20201112.ListTLSInspectionConfigurations"] }
def x-amz-target-completer-23 [] { ["NetworkFirewall_20201112.ListTagsForResource"] }
def x-amz-target-completer-24 [] { ["NetworkFirewall_20201112.PutResourcePolicy"] }
def x-amz-target-completer-25 [] { ["NetworkFirewall_20201112.TagResource"] }
def x-amz-target-completer-26 [] { ["NetworkFirewall_20201112.UntagResource"] }
def x-amz-target-completer-27 [] { ["NetworkFirewall_20201112.UpdateFirewallDeleteProtection"] }
def x-amz-target-completer-28 [] { ["NetworkFirewall_20201112.UpdateFirewallDescription"] }
def x-amz-target-completer-29 [] { ["NetworkFirewall_20201112.UpdateFirewallEncryptionConfiguration"] }
def x-amz-target-completer-30 [] { ["NetworkFirewall_20201112.UpdateFirewallPolicy"] }
def x-amz-target-completer-31 [] { ["NetworkFirewall_20201112.UpdateFirewallPolicyChangeProtection"] }
def x-amz-target-completer-32 [] { ["NetworkFirewall_20201112.UpdateLoggingConfiguration"] }
def x-amz-target-completer-33 [] { ["NetworkFirewall_20201112.UpdateRuleGroup"] }
def x-amz-target-completer-34 [] { ["NetworkFirewall_20201112.UpdateSubnetChangeProtection"] }
def x-amz-target-completer-35 [] { ["NetworkFirewall_20201112.UpdateTLSInspectionConfiguration"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-firewall-policy" "associate-subnets" "create-firewall" "create-firewall-policy" "create-rule-group" "create-tls-inspection-configuration" "delete-firewall" "delete-firewall-policy" "delete-resource-policy" "delete-rule-group" "delete-tls-inspection-configuration" "describe-firewall" "describe-firewall-policy" "describe-logging-configuration" "describe-resource-policy" "describe-rule-group" "describe-rule-group-metadata" "describe-tls-inspection-configuration" "disassociate-subnets" "list-firewall-policies" "list-firewalls" "list-rule-groups" "list-tls-inspection-configurations" "list-tags-for-resource" "put-resource-policy" "tag-resource" "untag-resource" "update-firewall-delete-protection" "update-firewall-description" "update-firewall-encryption-configuration" "update-firewall-policy" "update-firewall-policy-change-protection" "update-logging-configuration" "update-rule-group" "update-subnet-change-protection" "update-tls-inspection-configuration" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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

# Associates a FirewallPolicy to a Firewall. A firewall policy defines how to monitor and manage your VPC network traffic, using a collection of inspection rule groups and other settings. Each firewall requires one firewall policy association, and you can use the same firewall policy for multiple firewalls.
#
# POST /
# operationId: AssociateFirewallPolicy
export def "associate-firewall-policy" [
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
  --update-token: string # An optional token that you can use for optimistic locking. Network Firewall returns a token to your requests that access the firewall. The token marks the state of the firewall resource at the time of the request. To make an unconditional change to the firewall, omit the token in your update request. Without the token, Network Firewall performs your updates regardless of whether the firewall has changed since you last retrieved it. To make a conditional change to the firewall, provide the token in your update request. Network Firewall uses the token to ensure that the firewall hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the firewall again to get a current copy of it with a new token. Reapply your changes as needed, then try the operation again using the new token.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  firewall_policy_arn: string # The Amazon Resource Name (ARN) of the firewall policy.
]: any -> oneof<record<FirewallArn: string, FirewallName: string, FirewallPolicyArn: string, UpdateToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.AssociateFirewallPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "FirewallArn": $firewall_arn, "FirewallName": $firewall_name, "FirewallPolicyArn": $firewall_policy_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Associates the specified subnets in the Amazon VPC to the firewall. You can specify one subnet for each of the Availability Zones that the VPC spans. This request creates an Network Firewall firewall endpoint in each of the subnets. To enable the firewall's protections, you must also modify the VPC's route tables for each subnet's Availability Zone, to redirect the traffic that's coming into and going out of the zone through the firewall endpoint.
#
# POST /
# operationId: AssociateSubnets
export def "associate-subnets" [
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
  --update-token: string # An optional token that you can use for optimistic locking. Network Firewall returns a token to your requests that access the firewall. The token marks the state of the firewall resource at the time of the request. To make an unconditional change to the firewall, omit the token in your update request. Without the token, Network Firewall performs your updates regardless of whether the firewall has changed since you last retrieved it. To make a conditional change to the firewall, provide the token in your update request. Network Firewall uses the token to ensure that the firewall hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the firewall again to get a current copy of it with a new token. Reapply your changes as needed, then try the operation again using the new token.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  subnet_mappings: list # The IDs of the subnets that you want to associate with the firewall. — item shape: {SubnetId: string, IPAddressType?: "DUALSTACK"|"IPV4"|"IPV6"}
]: any -> oneof<record<FirewallArn: string, FirewallName: string, SubnetMappings: table<SubnetId: string, IPAddressType: string>, UpdateToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.AssociateSubnets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "FirewallArn": $firewall_arn, "FirewallName": $firewall_name, "SubnetMappings": $subnet_mappings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates an Network Firewall Firewall and accompanying FirewallStatus for a VPC. The firewall defines the configuration settings for an Network Firewall firewall. The settings that you can define at creation include the firewall policy, the subnets in your VPC to use for the firewall endpoints, and any tags that are attached to the firewall Amazon Web Services resource. After you create a firewall, you can provide additional settings, like the logging configuration. To update the settings for a firewall, you use the operations that apply to the settings themselves, for example UpdateLoggingConfiguration, AssociateSubnets, and UpdateFirewallDeleteProtection. To manage a firewall's tags, use the standard Amazon Web Services resource tagging operations, ListTagsForResource, TagResource, and UntagResource. To retrieve information about firewalls, use ListFirewalls and DescribeFirewall.
#
# POST /
# operationId: CreateFirewall
export def "create-firewall" [
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
  firewall_name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it.
  firewall_policy_arn: string # The Amazon Resource Name (ARN) of the FirewallPolicy that you want to use for the firewall.
  vpc_id: string # The unique identifier of the VPC where Network Firewall should create the firewall. You can't change this setting after you create the firewall.
  subnet_mappings: list # The public subnets to use for your Network Firewall firewalls. Each subnet must belong to a different Availability Zone in the VPC. Network Firewall creates a firewall endpoint in each subnet. — item shape: {SubnetId: string, IPAddressType?: "DUALSTACK"|"IPV4"|"IPV6"}
  --delete-protection: oneof<nothing, bool> # A flag indicating whether it is possible to delete the firewall. A setting of TRUE indicates that the firewall is protected against deletion. Use this setting to protect against accidentally deleting a firewall that is in use. When you create a firewall, the operation initializes this flag to TRUE.
  --subnet-change-protection: oneof<nothing, bool> # A setting indicating whether the firewall is protected against changes to the subnet associations. Use this setting to protect against accidentally modifying the subnet associations for a firewall that is in use. When you create a firewall, the operation initializes this setting to TRUE.
  --firewall-policy-change-protection: oneof<nothing, bool> # A setting indicating whether the firewall is protected against a change to the firewall policy association. Use this setting to protect against accidentally modifying the firewall policy for a firewall that is in use. When you create a firewall, the operation initializes this setting to TRUE.
  --description: string # A description of the firewall.
  --tags: list # The key:value pairs to associate with the resource. — item shape: {Key: string, Value: string}
  --encryption-configuration: record # A complex type that contains optional Amazon Web Services Key Management Service (KMS) encryption settings for your Network Firewall resources. Your data is encrypted by default with an Amazon Web Services owned key that Amazon Web Services owns and manages for you. You can use either the Amazon Web Services owned key, or provide your own customer managed key. To learn more about KMS encryption of your Network Firewall resources, see Encryption at rest with Amazon Web Services Key Managment Service (https://docs.aws.amazon.com/kms/latest/developerguide/kms-encryption-at-rest.html) in the Network Firewall Developer Guide. — shape: {KeyId?: string, Type: "CUSTOMER_KMS"|"AWS_OWNED_KMS_KEY"}
]: any -> oneof<record<Firewall: record<FirewallName: string, FirewallArn: string, FirewallPolicyArn: string, VpcId: string, SubnetMappings: list<record>, DeleteProtection: bool, SubnetChangeProtection: bool, FirewallPolicyChangeProtection: bool, Description: string, FirewallId: string, Tags: list<record>, EncryptionConfiguration: record<KeyId: string, Type: string>>, FirewallStatus: record<Status: string, ConfigurationSyncStateSummary: string, SyncStates: record, CapacityUsageSummary: record<CIDRs: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.CreateFirewall")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallName": $firewall_name, "FirewallPolicyArn": $firewall_policy_arn, "VpcId": $vpc_id, "SubnetMappings": $subnet_mappings, "DeleteProtection": $delete_protection, "SubnetChangeProtection": $subnet_change_protection, "FirewallPolicyChangeProtection": $firewall_policy_change_protection, "Description": $description, "Tags": $tags, "EncryptionConfiguration": $encryption_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates the firewall policy for the firewall according to the specifications. An Network Firewall firewall policy defines the behavior of a firewall, in a collection of stateless and stateful rule groups and other settings. You can use one firewall policy for multiple firewalls.
#
# POST /
# operationId: CreateFirewallPolicy
export def "create-firewall-policy" [
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
  firewall_policy_name: string # The descriptive name of the firewall policy. You can't change the name of a firewall policy after you create it.
  firewall_policy: record # The firewall policy defines the behavior of a firewall using a collection of stateless and stateful rule groups and other settings. You can use one firewall policy for multiple firewalls. This, along with FirewallPolicyResponse, define the policy. You can retrieve all objects for a firewall policy by calling DescribeFirewallPolicy. — shape: {StatelessRuleGroupReferences?: list, StatelessDefaultActions: list<string>, StatelessFragmentDefaultActions: list<string>, StatelessCustomActions?: list, StatefulRuleGroupReferences?: list, StatefulDefaultActions?: list<string>, StatefulEngineOptions?: record, TLSInspectionConfigurationArn?: string}
  --description: string # A description of the firewall policy.
  --tags: list # The key:value pairs to associate with the resource. — item shape: {Key: string, Value: string}
  --body-dry-run: oneof<nothing, bool> # Indicates whether you want Network Firewall to just check the validity of the request, rather than run the request. If set to TRUE, Network Firewall checks whether the request can run successfully, but doesn't actually make the requested changes. The call returns the value that the request would return if you ran it with dry run set to FALSE, but doesn't make additions or changes to your resources. This option allows you to make sure that you have the required permissions to run the request and that your request parameters are valid. If set to FALSE, Network Firewall makes the requested changes to your resources. (spec name: DryRun)
  --encryption-configuration: record # A complex type that contains optional Amazon Web Services Key Management Service (KMS) encryption settings for your Network Firewall resources. Your data is encrypted by default with an Amazon Web Services owned key that Amazon Web Services owns and manages for you. You can use either the Amazon Web Services owned key, or provide your own customer managed key. To learn more about KMS encryption of your Network Firewall resources, see Encryption at rest with Amazon Web Services Key Managment Service (https://docs.aws.amazon.com/kms/latest/developerguide/kms-encryption-at-rest.html) in the Network Firewall Developer Guide. — shape: {KeyId?: string, Type: "CUSTOMER_KMS"|"AWS_OWNED_KMS_KEY"}
]: any -> oneof<record<UpdateToken: string, FirewallPolicyResponse: record<FirewallPolicyName: string, FirewallPolicyArn: string, FirewallPolicyId: string, Description: string, FirewallPolicyStatus: string, Tags: list<record>, ConsumedStatelessRuleCapacity: int, ConsumedStatefulRuleCapacity: int, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, LastModifiedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.CreateFirewallPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallPolicyName": $firewall_policy_name, "FirewallPolicy": $firewall_policy, "Description": $description, "Tags": $tags, "DryRun": $body_dry_run, "EncryptionConfiguration": $encryption_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates the specified stateless or stateful rule group, which includes the rules for network traffic inspection, a capacity setting, and tags. You provide your rule group specification in your request using either RuleGroup or Rules.
#
# POST /
# operationId: CreateRuleGroup
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  rule_group_name: string # The descriptive name of the rule group. You can't change the name of a rule group after you create it.
  --rule-group: record # The object that defines the rules in a rule group. This, along with RuleGroupResponse, define the rule group. You can retrieve all objects for a rule group by calling DescribeRuleGroup. Network Firewall uses a rule group to inspect and control network traffic. You define stateless rule groups to inspect individual packets and you define stateful rule groups to inspect packets in the context of their traffic flow. To use a rule group, you include it by reference in an Network Firewall firewall policy, then you use the policy in a firewall. You can reference a rule group from more than one firewall policy, and you can use a firewall policy in more than one firewall. — shape: {RuleVariables?: record, ReferenceSets?: record, RulesSource: record, StatefulRuleOptions?: record}
  --rules: string # A string containing stateful rule group rules specifications in Suricata flat format, with one rule per line. Use this to import your existing Suricata compatible rule groups. You must provide either this rules setting or a populated RuleGroup setting, but not both. You can provide your rule group specification in Suricata flat format through this setting when you create or update your rule group. The call response returns a RuleGroup object that Network Firewall has populated from your string.
  type: string@type-completer # Indicates whether the rule group is stateless or stateful. If the rule group is stateless, it contains stateless rules. If it is stateful, it contains stateful rules.
  --description: string # A description of the rule group.
  capacity: int # The maximum operating resources that this rule group can use. Rule group capacity is fixed at creation. When you update a rule group, you are limited to this capacity. When you reference a rule group from a firewall policy, Network Firewall reserves this capacity for the rule group. You can retrieve the capacity that would be required for a rule group before you create the rule group by calling CreateRuleGroup with DryRun set to TRUE. You can't change or exceed this capacity when you update the rule group, so leave room for your rule group to grow. Capacity for a stateless rule group For a stateless rule group, the capacity required is the sum of the capacity requirements of the individual rules that you expect to have in the rule group. To calculate the capacity requirement of a single rule, multiply the capacity requirement values of each of the rule's match settings: A match setting with no criteria specified has a value of 1. A match setting with Any specified has a value of 1. All other match settings have a value equal to the number of elements provided in the setting. For example, a protocol setting ["UDP"] and a source setting ["10.0.0.0/24"] each have a value of 1. A protocol setting ["UDP","TCP"] has a value of 2. A source setting ["10.0.0.0/24","10.0.0.1/24","10.0.0.2/24"] has a value of 3. A rule with no criteria specified in any of its match settings has a capacity requirement of 1. A rule with protocol setting ["UDP","TCP"], source setting ["10.0.0.0/24","10.0.0.1/24","10.0.0.2/24"], and a single specification or no specification for each of the other match settings has a capacity requirement of 6. Capacity for a stateful rule group For a stateful rule group, the minimum capacity required is the number of individual rules that you expect to have in the rule group.
  --tags: list # The key:value pairs to associate with the resource. — item shape: {Key: string, Value: string}
  --body-dry-run: oneof<nothing, bool> # Indicates whether you want Network Firewall to just check the validity of the request, rather than run the request. If set to TRUE, Network Firewall checks whether the request can run successfully, but doesn't actually make the requested changes. The call returns the value that the request would return if you ran it with dry run set to FALSE, but doesn't make additions or changes to your resources. This option allows you to make sure that you have the required permissions to run the request and that your request parameters are valid. If set to FALSE, Network Firewall makes the requested changes to your resources. (spec name: DryRun)
  --encryption-configuration: record # A complex type that contains optional Amazon Web Services Key Management Service (KMS) encryption settings for your Network Firewall resources. Your data is encrypted by default with an Amazon Web Services owned key that Amazon Web Services owns and manages for you. You can use either the Amazon Web Services owned key, or provide your own customer managed key. To learn more about KMS encryption of your Network Firewall resources, see Encryption at rest with Amazon Web Services Key Managment Service (https://docs.aws.amazon.com/kms/latest/developerguide/kms-encryption-at-rest.html) in the Network Firewall Developer Guide. — shape: {KeyId?: string, Type: "CUSTOMER_KMS"|"AWS_OWNED_KMS_KEY"}
  --source-metadata: record # High-level information about the managed rule group that your own rule group is copied from. You can use the the metadata to track version updates made to the originating rule group. You can retrieve all objects for a rule group by calling DescribeRuleGroup (https://docs.aws.amazon.com/network-firewall/latest/APIReference/API_DescribeRuleGroup.html). — shape: {SourceArn?: string, SourceUpdateToken?: string}
]: any -> oneof<record<UpdateToken: string, RuleGroupResponse: record<RuleGroupArn: string, RuleGroupName: string, RuleGroupId: string, Description: string, Type: string, Capacity: int, RuleGroupStatus: string, Tags: list<record>, ConsumedCapacity: int, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, SourceMetadata: record<SourceArn: string, SourceUpdateToken: string>, SnsTopic: string, LastModifiedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.CreateRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupName": $rule_group_name, "RuleGroup": $rule_group, "Rules": $rules, "Type": $type, "Description": $description, "Capacity": $capacity, "Tags": $tags, "DryRun": $body_dry_run, "EncryptionConfiguration": $encryption_configuration, "SourceMetadata": $source_metadata} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates an Network Firewall TLS inspection configuration. A TLS inspection configuration contains the Certificate Manager certificate references that Network Firewall uses to decrypt and re-encrypt inbound traffic. After you create a TLS inspection configuration, you associate it with a firewall policy. To update the settings for a TLS inspection configuration, use UpdateTLSInspectionConfiguration. To manage a TLS inspection configuration's tags, use the standard Amazon Web Services resource tagging operations, ListTagsForResource, TagResource, and UntagResource. To retrieve information about TLS inspection configurations, use ListTLSInspectionConfigurations and DescribeTLSInspectionConfiguration. For more information about TLS inspection configurations, see Decrypting SSL/TLS traffic with TLS inspection configurations (https://docs.aws.amazon.com/network-firewall/latest/developerguide/tls-inspection.html) in the Network Firewall Developer Guide.
#
# POST /
# operationId: CreateTLSInspectionConfiguration
export def "create-tls-inspection-configuration" [
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
  tls_inspection_configuration_name: string # The descriptive name of the TLS inspection configuration. You can't change the name of a TLS inspection configuration after you create it.
  tls_inspection_configuration: record # The object that defines a TLS inspection configuration. This, along with TLSInspectionConfigurationResponse, define the TLS inspection configuration. You can retrieve all objects for a TLS inspection configuration by calling DescribeTLSInspectionConfiguration. Network Firewall uses a TLS inspection configuration to decrypt traffic. Network Firewall re-encrypts the traffic before sending it to its destination. To use a TLS inspection configuration, you add it to a Network Firewall firewall policy, then you apply the firewall policy to a firewall. Network Firewall acts as a proxy service to decrypt and inspect inbound traffic. You can reference a TLS inspection configuration from more than one firewall policy, and you can use a firewall policy in more than one firewall. For more information about using TLS inspection configurations, see Decrypting SSL/TLS traffic with TLS inspection configurations (https://docs.aws.amazon.com/network-firewall/latest/developerguide/tls-inspection.html) in the Network Firewall Developer Guide. — shape: {ServerCertificateConfigurations?: list}
  --description: string # A description of the TLS inspection configuration.
  --tags: list # The key:value pairs to associate with the resource. — item shape: {Key: string, Value: string}
  --encryption-configuration: record # A complex type that contains optional Amazon Web Services Key Management Service (KMS) encryption settings for your Network Firewall resources. Your data is encrypted by default with an Amazon Web Services owned key that Amazon Web Services owns and manages for you. You can use either the Amazon Web Services owned key, or provide your own customer managed key. To learn more about KMS encryption of your Network Firewall resources, see Encryption at rest with Amazon Web Services Key Managment Service (https://docs.aws.amazon.com/kms/latest/developerguide/kms-encryption-at-rest.html) in the Network Firewall Developer Guide. — shape: {KeyId?: string, Type: "CUSTOMER_KMS"|"AWS_OWNED_KMS_KEY"}
]: any -> oneof<record<UpdateToken: string, TLSInspectionConfigurationResponse: record<TLSInspectionConfigurationArn: string, TLSInspectionConfigurationName: string, TLSInspectionConfigurationId: string, TLSInspectionConfigurationStatus: string, Description: string, Tags: list<record>, LastModifiedTime: string, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, Certificates: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.CreateTLSInspectionConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TLSInspectionConfigurationName": $tls_inspection_configuration_name, "TLSInspectionConfiguration": $tls_inspection_configuration, "Description": $description, "Tags": $tags, "EncryptionConfiguration": $encryption_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes the specified Firewall and its FirewallStatus. This operation requires the firewall's DeleteProtection flag to be FALSE. You can't revert this operation. You can check whether a firewall is in use by reviewing the route tables for the Availability Zones where you have firewall subnet mappings. Retrieve the subnet mappings by calling DescribeFirewall. You define and update the route tables through Amazon VPC. As needed, update the route tables for the zones to remove the firewall endpoints. When the route tables no longer use the firewall endpoints, you can remove the firewall safely. To delete a firewall, remove the delete protection if you need to using UpdateFirewallDeleteProtection, then delete the firewall by calling DeleteFirewall.
#
# POST /
# operationId: DeleteFirewall
export def "delete-firewall" [
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
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
]: any -> oneof<record<Firewall: record<FirewallName: string, FirewallArn: string, FirewallPolicyArn: string, VpcId: string, SubnetMappings: list<record>, DeleteProtection: bool, SubnetChangeProtection: bool, FirewallPolicyChangeProtection: bool, Description: string, FirewallId: string, Tags: list<record>, EncryptionConfiguration: record<KeyId: string, Type: string>>, FirewallStatus: record<Status: string, ConfigurationSyncStateSummary: string, SyncStates: record, CapacityUsageSummary: record<CIDRs: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DeleteFirewall")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallName": $firewall_name, "FirewallArn": $firewall_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes the specified FirewallPolicy.
#
# POST /
# operationId: DeleteFirewallPolicy
export def "delete-firewall-policy" [
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
  --firewall-policy-name: string # The descriptive name of the firewall policy. You can't change the name of a firewall policy after you create it. You must specify the ARN or the name, and you can specify both.
  --firewall-policy-arn: string # The Amazon Resource Name (ARN) of the firewall policy. You must specify the ARN or the name, and you can specify both.
]: any -> oneof<record<FirewallPolicyResponse: record<FirewallPolicyName: string, FirewallPolicyArn: string, FirewallPolicyId: string, Description: string, FirewallPolicyStatus: string, Tags: list<record>, ConsumedStatelessRuleCapacity: int, ConsumedStatefulRuleCapacity: int, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, LastModifiedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DeleteFirewallPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallPolicyName": $firewall_policy_name, "FirewallPolicyArn": $firewall_policy_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes a resource policy that you created in a PutResourcePolicy request.
#
# POST /
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the rule group or firewall policy whose resource policy you want to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DeleteResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  --rule-group-name: string # The descriptive name of the rule group. You can't change the name of a rule group after you create it. You must specify the ARN or the name, and you can specify both.
  --rule-group-arn: string # The Amazon Resource Name (ARN) of the rule group. You must specify the ARN or the name, and you can specify both.
  --type: string@type-completer # Indicates whether the rule group is stateless or stateful. If the rule group is stateless, it contains stateless rules. If it is stateful, it contains stateful rules. This setting is required for requests that do not include the RuleGroupARN.
]: any -> oneof<record<RuleGroupResponse: record<RuleGroupArn: string, RuleGroupName: string, RuleGroupId: string, Description: string, Type: string, Capacity: int, RuleGroupStatus: string, Tags: list<record>, ConsumedCapacity: int, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, SourceMetadata: record<SourceArn: string, SourceUpdateToken: string>, SnsTopic: string, LastModifiedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DeleteRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupName": $rule_group_name, "RuleGroupArn": $rule_group_arn, "Type": $type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes the specified TLSInspectionConfiguration.
#
# POST /
# operationId: DeleteTLSInspectionConfiguration
export def "delete-tls-inspection-configuration" [
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
  --tls-inspection-configuration-arn: string # The Amazon Resource Name (ARN) of the TLS inspection configuration. You must specify the ARN or the name, and you can specify both.
  --tls-inspection-configuration-name: string # The descriptive name of the TLS inspection configuration. You can't change the name of a TLS inspection configuration after you create it. You must specify the ARN or the name, and you can specify both.
]: any -> oneof<record<TLSInspectionConfigurationResponse: record<TLSInspectionConfigurationArn: string, TLSInspectionConfigurationName: string, TLSInspectionConfigurationId: string, TLSInspectionConfigurationStatus: string, Description: string, Tags: list<record>, LastModifiedTime: string, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, Certificates: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DeleteTLSInspectionConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TLSInspectionConfigurationArn": $tls_inspection_configuration_arn, "TLSInspectionConfigurationName": $tls_inspection_configuration_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the data objects for the specified firewall.
#
# POST /
# operationId: DescribeFirewall
export def "describe-firewall" [
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
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
]: any -> oneof<record<UpdateToken: string, Firewall: record<FirewallName: string, FirewallArn: string, FirewallPolicyArn: string, VpcId: string, SubnetMappings: list<record>, DeleteProtection: bool, SubnetChangeProtection: bool, FirewallPolicyChangeProtection: bool, Description: string, FirewallId: string, Tags: list<record>, EncryptionConfiguration: record<KeyId: string, Type: string>>, FirewallStatus: record<Status: string, ConfigurationSyncStateSummary: string, SyncStates: record, CapacityUsageSummary: record<CIDRs: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DescribeFirewall")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallName": $firewall_name, "FirewallArn": $firewall_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the data objects for the specified firewall policy.
#
# POST /
# operationId: DescribeFirewallPolicy
export def "describe-firewall-policy" [
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
  --firewall-policy-name: string # The descriptive name of the firewall policy. You can't change the name of a firewall policy after you create it. You must specify the ARN or the name, and you can specify both.
  --firewall-policy-arn: string # The Amazon Resource Name (ARN) of the firewall policy. You must specify the ARN or the name, and you can specify both.
]: any -> oneof<record<UpdateToken: string, FirewallPolicyResponse: record<FirewallPolicyName: string, FirewallPolicyArn: string, FirewallPolicyId: string, Description: string, FirewallPolicyStatus: string, Tags: list<record>, ConsumedStatelessRuleCapacity: int, ConsumedStatefulRuleCapacity: int, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, LastModifiedTime: string>, FirewallPolicy: record<StatelessRuleGroupReferences: list<record>, StatelessDefaultActions: list<string>, StatelessFragmentDefaultActions: list<string>, StatelessCustomActions: list<record>, StatefulRuleGroupReferences: list<record>, StatefulDefaultActions: list<string>, StatefulEngineOptions: record<RuleOrder: string, StreamExceptionPolicy: string>, TLSInspectionConfigurationArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DescribeFirewallPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallPolicyName": $firewall_policy_name, "FirewallPolicyArn": $firewall_policy_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the logging configuration for the specified firewall.
#
# POST /
# operationId: DescribeLoggingConfiguration
export def "describe-logging-configuration" [
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
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
]: any -> oneof<record<FirewallArn: string, LoggingConfiguration: record<LogDestinationConfigs: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DescribeLoggingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallArn": $firewall_arn, "FirewallName": $firewall_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves a resource policy that you created in a PutResourcePolicy request.
#
# POST /
# operationId: DescribeResourcePolicy
export def "describe-resource-policy" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the rule group or firewall policy whose resource policy you want to retrieve.
]: any -> oneof<record<Policy: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DescribeResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the data objects for the specified rule group.
#
# POST /
# operationId: DescribeRuleGroup
export def "describe-rule-group" [
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
  --rule-group-name: string # The descriptive name of the rule group. You can't change the name of a rule group after you create it. You must specify the ARN or the name, and you can specify both.
  --rule-group-arn: string # The Amazon Resource Name (ARN) of the rule group. You must specify the ARN or the name, and you can specify both.
  --type: string@type-completer # Indicates whether the rule group is stateless or stateful. If the rule group is stateless, it contains stateless rules. If it is stateful, it contains stateful rules. This setting is required for requests that do not include the RuleGroupARN.
]: any -> oneof<record<UpdateToken: string, RuleGroup: record<RuleVariables: record<IPSets: record, PortSets: record>, ReferenceSets: record<IPSetReferences: record>, RulesSource: record<RulesString: string, RulesSourceList: record, StatefulRules: list, StatelessRulesAndCustomActions: record>, StatefulRuleOptions: record<RuleOrder: string>>, RuleGroupResponse: record<RuleGroupArn: string, RuleGroupName: string, RuleGroupId: string, Description: string, Type: string, Capacity: int, RuleGroupStatus: string, Tags: list<record>, ConsumedCapacity: int, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, SourceMetadata: record<SourceArn: string, SourceUpdateToken: string>, SnsTopic: string, LastModifiedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DescribeRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupName": $rule_group_name, "RuleGroupArn": $rule_group_arn, "Type": $type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# High-level information about a rule group, returned by operations like create and describe. You can use the information provided in the metadata to retrieve and manage a rule group. You can retrieve all objects for a rule group by calling DescribeRuleGroup.
#
# POST /
# operationId: DescribeRuleGroupMetadata
export def "describe-rule-group-metadata" [
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
  --rule-group-name: string # The descriptive name of the rule group. You can't change the name of a rule group after you create it. You must specify the ARN or the name, and you can specify both.
  --rule-group-arn: string # The descriptive name of the rule group. You can't change the name of a rule group after you create it. You must specify the ARN or the name, and you can specify both.
  --type: string@type-completer # Indicates whether the rule group is stateless or stateful. If the rule group is stateless, it contains stateless rules. If it is stateful, it contains stateful rules. This setting is required for requests that do not include the RuleGroupARN.
]: any -> oneof<record<RuleGroupArn: string, RuleGroupName: string, Description: string, Type: string, Capacity: int, StatefulRuleOptions: record<RuleOrder: string>, LastModifiedTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DescribeRuleGroupMetadata")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupName": $rule_group_name, "RuleGroupArn": $rule_group_arn, "Type": $type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Returns the data objects for the specified TLS inspection configuration.
#
# POST /
# operationId: DescribeTLSInspectionConfiguration
export def "describe-tls-inspection-configuration" [
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
  --tls-inspection-configuration-arn: string # The Amazon Resource Name (ARN) of the TLS inspection configuration. You must specify the ARN or the name, and you can specify both.
  --tls-inspection-configuration-name: string # The descriptive name of the TLS inspection configuration. You can't change the name of a TLS inspection configuration after you create it. You must specify the ARN or the name, and you can specify both.
]: any -> oneof<record<UpdateToken: string, TLSInspectionConfiguration: record<ServerCertificateConfigurations: list<record>>, TLSInspectionConfigurationResponse: record<TLSInspectionConfigurationArn: string, TLSInspectionConfigurationName: string, TLSInspectionConfigurationId: string, TLSInspectionConfigurationStatus: string, Description: string, Tags: list<record>, LastModifiedTime: string, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, Certificates: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DescribeTLSInspectionConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TLSInspectionConfigurationArn": $tls_inspection_configuration_arn, "TLSInspectionConfigurationName": $tls_inspection_configuration_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Removes the specified subnet associations from the firewall. This removes the firewall endpoints from the subnets and removes any network filtering protections that the endpoints were providing.
#
# POST /
# operationId: DisassociateSubnets
export def "disassociate-subnets" [
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
  --update-token: string # An optional token that you can use for optimistic locking. Network Firewall returns a token to your requests that access the firewall. The token marks the state of the firewall resource at the time of the request. To make an unconditional change to the firewall, omit the token in your update request. Without the token, Network Firewall performs your updates regardless of whether the firewall has changed since you last retrieved it. To make a conditional change to the firewall, provide the token in your update request. Network Firewall uses the token to ensure that the firewall hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the firewall again to get a current copy of it with a new token. Reapply your changes as needed, then try the operation again using the new token.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  subnet_ids: list<string> # The unique identifiers for the subnets that you want to disassociate.
]: any -> oneof<record<FirewallArn: string, FirewallName: string, SubnetMappings: table<SubnetId: string, IPAddressType: string>, UpdateToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.DisassociateSubnets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "FirewallArn": $firewall_arn, "FirewallName": $firewall_name, "SubnetIds": $subnet_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves the metadata for the firewall policies that you have defined. Depending on your setting for max results and the number of firewall policies, a single call might not return the full list.
#
# POST /
# operationId: ListFirewallPolicies
export def "list-firewall-policies" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  --body-next-token: string # When you request a list of objects with a MaxResults setting, if the number of objects that are still available for retrieval exceeds the maximum you requested, Network Firewall returns a NextToken value in the response. To retrieve the next batch of objects, use the token returned from the prior request in your next request. (spec name: NextToken)
  --body-max-results: int # The maximum number of objects that you want Network Firewall to return for this request. If more objects are available, in the response, Network Firewall provides a NextToken value that you can use in a subsequent call to get the next batch of objects. (spec name: MaxResults)
]: any -> oneof<record<NextToken: string, FirewallPolicies: table<Name: string, Arn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.ListFirewallPolicies")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves the metadata for the firewalls that you have defined. If you provide VPC identifiers in your request, this returns only the firewalls for those VPCs. Depending on your setting for max results and the number of firewalls, a single call might not return the full list.
#
# POST /
# operationId: ListFirewalls
export def "list-firewalls" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  --body-next-token: string # When you request a list of objects with a MaxResults setting, if the number of objects that are still available for retrieval exceeds the maximum you requested, Network Firewall returns a NextToken value in the response. To retrieve the next batch of objects, use the token returned from the prior request in your next request. (spec name: NextToken)
  --vpc-ids: list<string> # The unique identifiers of the VPCs that you want Network Firewall to retrieve the firewalls for. Leave this blank to retrieve all firewalls that you have defined.
  --body-max-results: int # The maximum number of objects that you want Network Firewall to return for this request. If more objects are available, in the response, Network Firewall provides a NextToken value that you can use in a subsequent call to get the next batch of objects. (spec name: MaxResults)
]: any -> oneof<record<NextToken: string, Firewalls: table<FirewallName: string, FirewallArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.ListFirewalls")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "VpcIds": $vpc_ids, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves the metadata for the rule groups that you have defined. Depending on your setting for max results and the number of rule groups, a single call might not return the full list.
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
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  --body-next-token: string # When you request a list of objects with a MaxResults setting, if the number of objects that are still available for retrieval exceeds the maximum you requested, Network Firewall returns a NextToken value in the response. To retrieve the next batch of objects, use the token returned from the prior request in your next request. (spec name: NextToken)
  --body-max-results: int # The maximum number of objects that you want Network Firewall to return for this request. If more objects are available, in the response, Network Firewall provides a NextToken value that you can use in a subsequent call to get the next batch of objects. (spec name: MaxResults)
  --scope: string@scope-completer # The scope of the request. The default setting of ACCOUNT or a setting of NULL returns all of the rule groups in your account. A setting of MANAGED returns all available managed rule groups.
  --managed-type: string@managed-type-completer # Indicates the general category of the Amazon Web Services managed rule group.
  --type: string@type-completer # Indicates whether the rule group is stateless or stateful. If the rule group is stateless, it contains stateless rules. If it is stateful, it contains stateful rules.
]: any -> oneof<record<NextToken: string, RuleGroups: table<Name: string, Arn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.ListRuleGroups")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "MaxResults": $body_max_results, "Scope": $scope, "ManagedType": $managed_type, "Type": $type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves the metadata for the TLS inspection configurations that you have defined. Depending on your setting for max results and the number of TLS inspection configurations, a single call might not return the full list.
#
# POST /
# operationId: ListTLSInspectionConfigurations
export def "list-tls-inspection-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  --body-next-token: string # When you request a list of objects with a MaxResults setting, if the number of objects that are still available for retrieval exceeds the maximum you requested, Network Firewall returns a NextToken value in the response. To retrieve the next batch of objects, use the token returned from the prior request in your next request. (spec name: NextToken)
  --body-max-results: int # The maximum number of objects that you want Network Firewall to return for this request. If more objects are available, in the response, Network Firewall provides a NextToken value that you can use in a subsequent call to get the next batch of objects. (spec name: MaxResults)
]: any -> oneof<record<NextToken: string, TLSInspectionConfigurations: table<Name: string, Arn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.ListTLSInspectionConfigurations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Retrieves the tags associated with the specified resource. Tags are key:value pairs that you can use to categorize and manage your resources, for purposes like billing. For example, you might set the tag key to "customer" and the value to the customer name or ID. You can specify one or more tags to add to each Amazon Web Services resource, up to 50 tags for a resource. You can tag the Amazon Web Services resources that you manage through Network Firewall: firewalls, firewall policies, and rule groups.
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  --body-next-token: string # When you request a list of objects with a MaxResults setting, if the number of objects that are still available for retrieval exceeds the maximum you requested, Network Firewall returns a NextToken value in the response. To retrieve the next batch of objects, use the token returned from the prior request in your next request. (spec name: NextToken)
  --body-max-results: int # The maximum number of objects that you want Network Firewall to return for this request. If more objects are available, in the response, Network Firewall provides a NextToken value that you can use in a subsequent call to get the next batch of objects. (spec name: MaxResults)
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
]: any -> oneof<record<NextToken: string, Tags: table<Key: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.ListTagsForResource")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $body_next_token, "MaxResults": $body_max_results, "ResourceArn": $resource_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Creates or updates an IAM policy for your rule group or firewall policy. Use this to share rule groups and firewall policies between accounts. This operation works in conjunction with the Amazon Web Services Resource Access Manager (RAM) service to manage resource sharing for Network Firewall. Use this operation to create or update a resource policy for your rule group or firewall policy. In the policy, you specify the accounts that you want to share the resource with and the operations that you want the accounts to be able to perform. When you add an account in the resource policy, you then run the following Resource Access Manager (RAM) operations to access and accept the shared rule group or firewall policy. GetResourceShareInvitations (https://docs.aws.amazon.com/ram/latest/APIReference/API_GetResourceShareInvitations.html) - Returns the Amazon Resource Names (ARNs) of the resource share invitations. AcceptResourceShareInvitation (https://docs.aws.amazon.com/ram/latest/APIReference/API_AcceptResourceShareInvitation.html) - Accepts the share invitation for a specified resource share. For additional information about resource sharing using RAM, see Resource Access Manager User Guide (https://docs.aws.amazon.com/ram/latest/userguide/what-is.html).
#
# POST /
# operationId: PutResourcePolicy
export def "put-resource-policy" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the account that you want to share rule groups and firewall policies with.
  policy: string # The IAM policy statement that lists the accounts that you want to share your rule group or firewall policy with and the operations that you want the accounts to be able to perform. For a rule group resource, you can specify the following operations in the Actions section of the statement: network-firewall:CreateFirewallPolicy network-firewall:UpdateFirewallPolicy network-firewall:ListRuleGroups For a firewall policy resource, you can specify the following operations in the Actions section of the statement: network-firewall:CreateFirewall network-firewall:UpdateFirewall network-firewall:AssociateFirewallPolicy network-firewall:ListFirewallPolicies In the Resource section of the statement, you specify the ARNs for the rule groups and firewall policies that you want to share with the account that you specified in Arn.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.PutResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Policy": $policy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Adds the specified tags to the specified resource. Tags are key:value pairs that you can use to categorize and manage your resources, for purposes like billing. For example, you might set the tag key to "customer" and the value to the customer name or ID. You can specify one or more tags to add to each Amazon Web Services resource, up to 50 tags for a resource. You can tag the Amazon Web Services resources that you manage through Network Firewall: firewalls, firewall policies, and rule groups.
#
# POST /
# operationId: TagResource
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
  tags: list # item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Removes the tags with the specified keys from the specified resource. Tags are key:value pairs that you can use to categorize and manage your resources, for purposes like billing. For example, you might set the tag key to "customer" and the value to the customer name or ID. You can specify one or more tags to add to each Amazon Web Services resource, up to 50 tags for a resource. You can manage tags for the Amazon Web Services resources that you manage through Network Firewall: firewalls, firewall policies, and rule groups.
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
  tag_keys: list<string>
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Modifies the flag, DeleteProtection, which indicates whether it is possible to delete the firewall. If the flag is set to TRUE, the firewall is protected against deletion. This setting helps protect against accidentally deleting a firewall that's in use.
#
# POST /
# operationId: UpdateFirewallDeleteProtection
export def "update-firewall-delete-protection" [
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
  --update-token: string # An optional token that you can use for optimistic locking. Network Firewall returns a token to your requests that access the firewall. The token marks the state of the firewall resource at the time of the request. To make an unconditional change to the firewall, omit the token in your update request. Without the token, Network Firewall performs your updates regardless of whether the firewall has changed since you last retrieved it. To make a conditional change to the firewall, provide the token in your update request. Network Firewall uses the token to ensure that the firewall hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the firewall again to get a current copy of it with a new token. Reapply your changes as needed, then try the operation again using the new token.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  --delete-protection: oneof<nothing, bool> # A flag indicating whether it is possible to delete the firewall. A setting of TRUE indicates that the firewall is protected against deletion. Use this setting to protect against accidentally deleting a firewall that is in use. When you create a firewall, the operation initializes this flag to TRUE.
]: any -> oneof<record<FirewallArn: string, FirewallName: string, DeleteProtection: bool, UpdateToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UpdateFirewallDeleteProtection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "FirewallArn": $firewall_arn, "FirewallName": $firewall_name, "DeleteProtection": $delete_protection} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "DeleteProtection") == null) { error make --unspanned { msg: "required body field 'DeleteProtection' missing: pass --delete-protection or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Modifies the description for the specified firewall. Use the description to help you identify the firewall when you're working with it.
#
# POST /
# operationId: UpdateFirewallDescription
export def "update-firewall-description" [
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
  --update-token: string # An optional token that you can use for optimistic locking. Network Firewall returns a token to your requests that access the firewall. The token marks the state of the firewall resource at the time of the request. To make an unconditional change to the firewall, omit the token in your update request. Without the token, Network Firewall performs your updates regardless of whether the firewall has changed since you last retrieved it. To make a conditional change to the firewall, provide the token in your update request. Network Firewall uses the token to ensure that the firewall hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the firewall again to get a current copy of it with a new token. Reapply your changes as needed, then try the operation again using the new token.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  --description: string # The new description for the firewall. If you omit this setting, Network Firewall removes the description for the firewall.
]: any -> oneof<record<FirewallArn: string, FirewallName: string, Description: string, UpdateToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UpdateFirewallDescription")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "FirewallArn": $firewall_arn, "FirewallName": $firewall_name, "Description": $description} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# A complex type that contains settings for encryption of your firewall resources.
#
# POST /
# operationId: UpdateFirewallEncryptionConfiguration
export def "update-firewall-encryption-configuration" [
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
  --update-token: string # An optional token that you can use for optimistic locking. Network Firewall returns a token to your requests that access the firewall. The token marks the state of the firewall resource at the time of the request. To make an unconditional change to the firewall, omit the token in your update request. Without the token, Network Firewall performs your updates regardless of whether the firewall has changed since you last retrieved it. To make a conditional change to the firewall, provide the token in your update request. Network Firewall uses the token to ensure that the firewall hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the firewall again to get a current copy of it with a new token. Reapply your changes as needed, then try the operation again using the new token.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it.
  --encryption-configuration: record # A complex type that contains optional Amazon Web Services Key Management Service (KMS) encryption settings for your Network Firewall resources. Your data is encrypted by default with an Amazon Web Services owned key that Amazon Web Services owns and manages for you. You can use either the Amazon Web Services owned key, or provide your own customer managed key. To learn more about KMS encryption of your Network Firewall resources, see Encryption at rest with Amazon Web Services Key Managment Service (https://docs.aws.amazon.com/kms/latest/developerguide/kms-encryption-at-rest.html) in the Network Firewall Developer Guide. — shape: {KeyId?: string, Type: "CUSTOMER_KMS"|"AWS_OWNED_KMS_KEY"}
]: any -> oneof<record<FirewallArn: string, FirewallName: string, UpdateToken: string, EncryptionConfiguration: record<KeyId: string, Type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UpdateFirewallEncryptionConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "FirewallArn": $firewall_arn, "FirewallName": $firewall_name, "EncryptionConfiguration": $encryption_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Updates the properties of the specified firewall policy.
#
# POST /
# operationId: UpdateFirewallPolicy
export def "update-firewall-policy" [
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
  update_token: string # A token used for optimistic locking. Network Firewall returns a token to your requests that access the firewall policy. The token marks the state of the policy resource at the time of the request. To make changes to the policy, you provide the token in your request. Network Firewall uses the token to ensure that the policy hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the firewall policy again to get a current copy of it with current token. Reapply your changes as needed, then try the operation again using the new token.
  --firewall-policy-arn: string # The Amazon Resource Name (ARN) of the firewall policy. You must specify the ARN or the name, and you can specify both.
  --firewall-policy-name: string # The descriptive name of the firewall policy. You can't change the name of a firewall policy after you create it. You must specify the ARN or the name, and you can specify both.
  firewall_policy: record # The firewall policy defines the behavior of a firewall using a collection of stateless and stateful rule groups and other settings. You can use one firewall policy for multiple firewalls. This, along with FirewallPolicyResponse, define the policy. You can retrieve all objects for a firewall policy by calling DescribeFirewallPolicy. — shape: {StatelessRuleGroupReferences?: list, StatelessDefaultActions: list<string>, StatelessFragmentDefaultActions: list<string>, StatelessCustomActions?: list, StatefulRuleGroupReferences?: list, StatefulDefaultActions?: list<string>, StatefulEngineOptions?: record, TLSInspectionConfigurationArn?: string}
  --description: string # A description of the firewall policy.
  --body-dry-run: oneof<nothing, bool> # Indicates whether you want Network Firewall to just check the validity of the request, rather than run the request. If set to TRUE, Network Firewall checks whether the request can run successfully, but doesn't actually make the requested changes. The call returns the value that the request would return if you ran it with dry run set to FALSE, but doesn't make additions or changes to your resources. This option allows you to make sure that you have the required permissions to run the request and that your request parameters are valid. If set to FALSE, Network Firewall makes the requested changes to your resources. (spec name: DryRun)
  --encryption-configuration: record # A complex type that contains optional Amazon Web Services Key Management Service (KMS) encryption settings for your Network Firewall resources. Your data is encrypted by default with an Amazon Web Services owned key that Amazon Web Services owns and manages for you. You can use either the Amazon Web Services owned key, or provide your own customer managed key. To learn more about KMS encryption of your Network Firewall resources, see Encryption at rest with Amazon Web Services Key Managment Service (https://docs.aws.amazon.com/kms/latest/developerguide/kms-encryption-at-rest.html) in the Network Firewall Developer Guide. — shape: {KeyId?: string, Type: "CUSTOMER_KMS"|"AWS_OWNED_KMS_KEY"}
]: any -> oneof<record<UpdateToken: string, FirewallPolicyResponse: record<FirewallPolicyName: string, FirewallPolicyArn: string, FirewallPolicyId: string, Description: string, FirewallPolicyStatus: string, Tags: list<record>, ConsumedStatelessRuleCapacity: int, ConsumedStatefulRuleCapacity: int, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, LastModifiedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UpdateFirewallPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "FirewallPolicyArn": $firewall_policy_arn, "FirewallPolicyName": $firewall_policy_name, "FirewallPolicy": $firewall_policy, "Description": $description, "DryRun": $body_dry_run, "EncryptionConfiguration": $encryption_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Modifies the flag, ChangeProtection, which indicates whether it is possible to change the firewall. If the flag is set to TRUE, the firewall is protected from changes. This setting helps protect against accidentally changing a firewall that's in use.
#
# POST /
# operationId: UpdateFirewallPolicyChangeProtection
export def "update-firewall-policy-change-protection" [
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
  --update-token: string # An optional token that you can use for optimistic locking. Network Firewall returns a token to your requests that access the firewall. The token marks the state of the firewall resource at the time of the request. To make an unconditional change to the firewall, omit the token in your update request. Without the token, Network Firewall performs your updates regardless of whether the firewall has changed since you last retrieved it. To make a conditional change to the firewall, provide the token in your update request. Network Firewall uses the token to ensure that the firewall hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the firewall again to get a current copy of it with a new token. Reapply your changes as needed, then try the operation again using the new token.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  --firewall-policy-change-protection: oneof<nothing, bool> # A setting indicating whether the firewall is protected against a change to the firewall policy association. Use this setting to protect against accidentally modifying the firewall policy for a firewall that is in use. When you create a firewall, the operation initializes this setting to TRUE.
]: any -> oneof<record<UpdateToken: string, FirewallArn: string, FirewallName: string, FirewallPolicyChangeProtection: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UpdateFirewallPolicyChangeProtection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "FirewallArn": $firewall_arn, "FirewallName": $firewall_name, "FirewallPolicyChangeProtection": $firewall_policy_change_protection} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "FirewallPolicyChangeProtection") == null) { error make --unspanned { msg: "required body field 'FirewallPolicyChangeProtection' missing: pass --firewall-policy-change-protection or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Sets the logging configuration for the specified firewall. To change the logging configuration, retrieve the LoggingConfiguration by calling DescribeLoggingConfiguration, then change it and provide the modified object to this update call. You must change the logging configuration one LogDestinationConfig at a time inside the retrieved LoggingConfiguration object. You can perform only one of the following actions in any call to UpdateLoggingConfiguration: Create a new log destination object by adding a single LogDestinationConfig array element to LogDestinationConfigs. Delete a log destination object by removing a single LogDestinationConfig array element from LogDestinationConfigs. Change the LogDestination setting in a single LogDestinationConfig array element. You can't change the LogDestinationType or LogType in a LogDestinationConfig. To change these settings, delete the existing LogDestinationConfig object and create a new one, using two separate calls to this update operation.
#
# POST /
# operationId: UpdateLoggingConfiguration
export def "update-logging-configuration" [
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
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  --logging-configuration: record # Defines how Network Firewall performs logging for a Firewall. — shape: {LogDestinationConfigs: list}
]: any -> oneof<record<FirewallArn: string, FirewallName: string, LoggingConfiguration: record<LogDestinationConfigs: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UpdateLoggingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FirewallArn": $firewall_arn, "FirewallName": $firewall_name, "LoggingConfiguration": $logging_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Updates the rule settings for the specified rule group. You use a rule group by reference in one or more firewall policies. When you modify a rule group, you modify all firewall policies that use the rule group. To update a rule group, first call DescribeRuleGroup to retrieve the current RuleGroup object, update the object as needed, and then provide the updated object to this call.
#
# POST /
# operationId: UpdateRuleGroup
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  update_token: string # A token used for optimistic locking. Network Firewall returns a token to your requests that access the rule group. The token marks the state of the rule group resource at the time of the request. To make changes to the rule group, you provide the token in your request. Network Firewall uses the token to ensure that the rule group hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the rule group again to get a current copy of it with a current token. Reapply your changes as needed, then try the operation again using the new token.
  --rule-group-arn: string # The Amazon Resource Name (ARN) of the rule group. You must specify the ARN or the name, and you can specify both.
  --rule-group-name: string # The descriptive name of the rule group. You can't change the name of a rule group after you create it. You must specify the ARN or the name, and you can specify both.
  --rule-group: record # The object that defines the rules in a rule group. This, along with RuleGroupResponse, define the rule group. You can retrieve all objects for a rule group by calling DescribeRuleGroup. Network Firewall uses a rule group to inspect and control network traffic. You define stateless rule groups to inspect individual packets and you define stateful rule groups to inspect packets in the context of their traffic flow. To use a rule group, you include it by reference in an Network Firewall firewall policy, then you use the policy in a firewall. You can reference a rule group from more than one firewall policy, and you can use a firewall policy in more than one firewall. — shape: {RuleVariables?: record, ReferenceSets?: record, RulesSource: record, StatefulRuleOptions?: record}
  --rules: string # A string containing stateful rule group rules specifications in Suricata flat format, with one rule per line. Use this to import your existing Suricata compatible rule groups. You must provide either this rules setting or a populated RuleGroup setting, but not both. You can provide your rule group specification in Suricata flat format through this setting when you create or update your rule group. The call response returns a RuleGroup object that Network Firewall has populated from your string.
  --type: string@type-completer # Indicates whether the rule group is stateless or stateful. If the rule group is stateless, it contains stateless rules. If it is stateful, it contains stateful rules. This setting is required for requests that do not include the RuleGroupARN.
  --description: string # A description of the rule group.
  --body-dry-run: oneof<nothing, bool> # Indicates whether you want Network Firewall to just check the validity of the request, rather than run the request. If set to TRUE, Network Firewall checks whether the request can run successfully, but doesn't actually make the requested changes. The call returns the value that the request would return if you ran it with dry run set to FALSE, but doesn't make additions or changes to your resources. This option allows you to make sure that you have the required permissions to run the request and that your request parameters are valid. If set to FALSE, Network Firewall makes the requested changes to your resources. (spec name: DryRun)
  --encryption-configuration: record # A complex type that contains optional Amazon Web Services Key Management Service (KMS) encryption settings for your Network Firewall resources. Your data is encrypted by default with an Amazon Web Services owned key that Amazon Web Services owns and manages for you. You can use either the Amazon Web Services owned key, or provide your own customer managed key. To learn more about KMS encryption of your Network Firewall resources, see Encryption at rest with Amazon Web Services Key Managment Service (https://docs.aws.amazon.com/kms/latest/developerguide/kms-encryption-at-rest.html) in the Network Firewall Developer Guide. — shape: {KeyId?: string, Type: "CUSTOMER_KMS"|"AWS_OWNED_KMS_KEY"}
  --source-metadata: record # High-level information about the managed rule group that your own rule group is copied from. You can use the the metadata to track version updates made to the originating rule group. You can retrieve all objects for a rule group by calling DescribeRuleGroup (https://docs.aws.amazon.com/network-firewall/latest/APIReference/API_DescribeRuleGroup.html). — shape: {SourceArn?: string, SourceUpdateToken?: string}
]: any -> oneof<record<UpdateToken: string, RuleGroupResponse: record<RuleGroupArn: string, RuleGroupName: string, RuleGroupId: string, Description: string, Type: string, Capacity: int, RuleGroupStatus: string, Tags: list<record>, ConsumedCapacity: int, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, SourceMetadata: record<SourceArn: string, SourceUpdateToken: string>, SnsTopic: string, LastModifiedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UpdateRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "RuleGroupArn": $rule_group_arn, "RuleGroupName": $rule_group_name, "RuleGroup": $rule_group, "Rules": $rules, "Type": $type, "Description": $description, "DryRun": $body_dry_run, "EncryptionConfiguration": $encryption_configuration, "SourceMetadata": $source_metadata} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# POST /
#
# operationId: UpdateSubnetChangeProtection
export def "update-subnet-change-protection" [
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
  --update-token: string # An optional token that you can use for optimistic locking. Network Firewall returns a token to your requests that access the firewall. The token marks the state of the firewall resource at the time of the request. To make an unconditional change to the firewall, omit the token in your update request. Without the token, Network Firewall performs your updates regardless of whether the firewall has changed since you last retrieved it. To make a conditional change to the firewall, provide the token in your update request. Network Firewall uses the token to ensure that the firewall hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the firewall again to get a current copy of it with a new token. Reapply your changes as needed, then try the operation again using the new token.
  --firewall-arn: string # The Amazon Resource Name (ARN) of the firewall. You must specify the ARN or the name, and you can specify both.
  --firewall-name: string # The descriptive name of the firewall. You can't change the name of a firewall after you create it. You must specify the ARN or the name, and you can specify both.
  --subnet-change-protection: oneof<nothing, bool> # A setting indicating whether the firewall is protected against changes to the subnet associations. Use this setting to protect against accidentally modifying the subnet associations for a firewall that is in use. When you create a firewall, the operation initializes this setting to TRUE.
]: any -> oneof<record<UpdateToken: string, FirewallArn: string, FirewallName: string, SubnetChangeProtection: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UpdateSubnetChangeProtection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"UpdateToken": $update_token, "FirewallArn": $firewall_arn, "FirewallName": $firewall_name, "SubnetChangeProtection": $subnet_change_protection} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "SubnetChangeProtection") == null) { error make --unspanned { msg: "required body field 'SubnetChangeProtection' missing: pass --subnet-change-protection or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Updates the TLS inspection configuration settings for the specified TLS inspection configuration. You use a TLS inspection configuration by reference in one or more firewall policies. When you modify a TLS inspection configuration, you modify all firewall policies that use the TLS inspection configuration. To update a TLS inspection configuration, first call DescribeTLSInspectionConfiguration to retrieve the current TLSInspectionConfiguration object, update the object as needed, and then provide the updated object to this call.
#
# POST /
# operationId: UpdateTLSInspectionConfiguration
export def "update-tls-inspection-configuration" [
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
  --tls-inspection-configuration-arn: string # The Amazon Resource Name (ARN) of the TLS inspection configuration.
  --tls-inspection-configuration-name: string # The descriptive name of the TLS inspection configuration. You can't change the name of a TLS inspection configuration after you create it.
  tls_inspection_configuration: record # The object that defines a TLS inspection configuration. This, along with TLSInspectionConfigurationResponse, define the TLS inspection configuration. You can retrieve all objects for a TLS inspection configuration by calling DescribeTLSInspectionConfiguration. Network Firewall uses a TLS inspection configuration to decrypt traffic. Network Firewall re-encrypts the traffic before sending it to its destination. To use a TLS inspection configuration, you add it to a Network Firewall firewall policy, then you apply the firewall policy to a firewall. Network Firewall acts as a proxy service to decrypt and inspect inbound traffic. You can reference a TLS inspection configuration from more than one firewall policy, and you can use a firewall policy in more than one firewall. For more information about using TLS inspection configurations, see Decrypting SSL/TLS traffic with TLS inspection configurations (https://docs.aws.amazon.com/network-firewall/latest/developerguide/tls-inspection.html) in the Network Firewall Developer Guide. — shape: {ServerCertificateConfigurations?: list}
  --description: string # A description of the TLS inspection configuration.
  --encryption-configuration: record # A complex type that contains optional Amazon Web Services Key Management Service (KMS) encryption settings for your Network Firewall resources. Your data is encrypted by default with an Amazon Web Services owned key that Amazon Web Services owns and manages for you. You can use either the Amazon Web Services owned key, or provide your own customer managed key. To learn more about KMS encryption of your Network Firewall resources, see Encryption at rest with Amazon Web Services Key Managment Service (https://docs.aws.amazon.com/kms/latest/developerguide/kms-encryption-at-rest.html) in the Network Firewall Developer Guide. — shape: {KeyId?: string, Type: "CUSTOMER_KMS"|"AWS_OWNED_KMS_KEY"}
  update_token: string # A token used for optimistic locking. Network Firewall returns a token to your requests that access the TLS inspection configuration. The token marks the state of the TLS inspection configuration resource at the time of the request. To make changes to the TLS inspection configuration, you provide the token in your request. Network Firewall uses the token to ensure that the TLS inspection configuration hasn't changed since you last retrieved it. If it has changed, the operation fails with an InvalidTokenException. If this happens, retrieve the TLS inspection configuration again to get a current copy of it with a current token. Reapply your changes as needed, then try the operation again using the new token.
]: any -> oneof<record<UpdateToken: string, TLSInspectionConfigurationResponse: record<TLSInspectionConfigurationArn: string, TLSInspectionConfigurationName: string, TLSInspectionConfigurationId: string, TLSInspectionConfigurationStatus: string, Description: string, Tags: list<record>, LastModifiedTime: string, NumberOfAssociations: int, EncryptionConfiguration: record<KeyId: string, Type: string>, Certificates: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "NetworkFirewall_20201112.UpdateTLSInspectionConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TLSInspectionConfigurationArn": $tls_inspection_configuration_arn, "TLSInspectionConfigurationName": $tls_inspection_configuration_name, "TLSInspectionConfiguration": $tls_inspection_configuration, "Description": $description, "EncryptionConfiguration": $encryption_configuration, "UpdateToken": $update_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
