# Auto-generated client for Amazon Route 53 Domains v2014-05-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/route53domains/2014-05-15/openapi.json
# Auth: --token flag or $env.AMAZON_ROUTE_53_DOMAINS_TOKEN

const BASE_URL = "http://route53domains.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_ROUTE_53_DOMAINS_TOKEN | default "" }
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

def base-url-completer [] { ["http://route53domains.us-east-1.amazonaws.com" "http://route53domains.us-east-2.amazonaws.com" "http://route53domains.us-west-1.amazonaws.com" "http://route53domains.us-west-2.amazonaws.com" "http://route53domains.us-gov-west-1.amazonaws.com" "http://route53domains.us-gov-east-1.amazonaws.com" "http://route53domains.ca-central-1.amazonaws.com" "http://route53domains.eu-north-1.amazonaws.com" "http://route53domains.eu-west-1.amazonaws.com" "http://route53domains.eu-west-2.amazonaws.com" "http://route53domains.eu-west-3.amazonaws.com" "http://route53domains.eu-central-1.amazonaws.com" "http://route53domains.eu-south-1.amazonaws.com" "http://route53domains.af-south-1.amazonaws.com" "http://route53domains.ap-northeast-1.amazonaws.com" "http://route53domains.ap-northeast-2.amazonaws.com" "http://route53domains.ap-northeast-3.amazonaws.com" "http://route53domains.ap-southeast-1.amazonaws.com" "http://route53domains.ap-southeast-2.amazonaws.com" "http://route53domains.ap-east-1.amazonaws.com" "http://route53domains.ap-south-1.amazonaws.com" "http://route53domains.sa-east-1.amazonaws.com" "http://route53domains.me-south-1.amazonaws.com" "https://route53domains.us-east-1.amazonaws.com" "https://route53domains.us-east-2.amazonaws.com" "https://route53domains.us-west-1.amazonaws.com" "https://route53domains.us-west-2.amazonaws.com" "https://route53domains.us-gov-west-1.amazonaws.com" "https://route53domains.us-gov-east-1.amazonaws.com" "https://route53domains.ca-central-1.amazonaws.com" "https://route53domains.eu-north-1.amazonaws.com" "https://route53domains.eu-west-1.amazonaws.com" "https://route53domains.eu-west-2.amazonaws.com" "https://route53domains.eu-west-3.amazonaws.com" "https://route53domains.eu-central-1.amazonaws.com" "https://route53domains.eu-south-1.amazonaws.com" "https://route53domains.af-south-1.amazonaws.com" "https://route53domains.ap-northeast-1.amazonaws.com" "https://route53domains.ap-northeast-2.amazonaws.com" "https://route53domains.ap-northeast-3.amazonaws.com" "https://route53domains.ap-southeast-1.amazonaws.com" "https://route53domains.ap-southeast-2.amazonaws.com" "https://route53domains.ap-east-1.amazonaws.com" "https://route53domains.ap-south-1.amazonaws.com" "https://route53domains.sa-east-1.amazonaws.com" "https://route53domains.me-south-1.amazonaws.com" "http://route53domains.cn-north-1.amazonaws.com.cn" "http://route53domains.cn-northwest-1.amazonaws.com.cn" "https://route53domains.cn-north-1.amazonaws.com.cn" "https://route53domains.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["Route53Domains_v20140515.AcceptDomainTransferFromAnotherAwsAccount"] }
def x-amz-target-completer-1 [] { ["Route53Domains_v20140515.AssociateDelegationSignerToDomain"] }
def x-amz-target-completer-2 [] { ["Route53Domains_v20140515.CancelDomainTransferToAnotherAwsAccount"] }
def x-amz-target-completer-3 [] { ["Route53Domains_v20140515.CheckDomainAvailability"] }
def x-amz-target-completer-4 [] { ["Route53Domains_v20140515.CheckDomainTransferability"] }
def x-amz-target-completer-5 [] { ["Route53Domains_v20140515.DeleteDomain"] }
def x-amz-target-completer-6 [] { ["Route53Domains_v20140515.DeleteTagsForDomain"] }
def x-amz-target-completer-7 [] { ["Route53Domains_v20140515.DisableDomainAutoRenew"] }
def x-amz-target-completer-8 [] { ["Route53Domains_v20140515.DisableDomainTransferLock"] }
def x-amz-target-completer-9 [] { ["Route53Domains_v20140515.DisassociateDelegationSignerFromDomain"] }
def x-amz-target-completer-10 [] { ["Route53Domains_v20140515.EnableDomainAutoRenew"] }
def x-amz-target-completer-11 [] { ["Route53Domains_v20140515.EnableDomainTransferLock"] }
def x-amz-target-completer-12 [] { ["Route53Domains_v20140515.GetContactReachabilityStatus"] }
def x-amz-target-completer-13 [] { ["Route53Domains_v20140515.GetDomainDetail"] }
def x-amz-target-completer-14 [] { ["Route53Domains_v20140515.GetDomainSuggestions"] }
def x-amz-target-completer-15 [] { ["Route53Domains_v20140515.GetOperationDetail"] }
def x-amz-target-completer-16 [] { ["Route53Domains_v20140515.ListDomains"] }
def sort-by-completer [] { ["SubmittedDate"] }
def sort-order-completer [] { ["ASC" "DESC"] }
def x-amz-target-completer-17 [] { ["Route53Domains_v20140515.ListOperations"] }
def x-amz-target-completer-18 [] { ["Route53Domains_v20140515.ListPrices"] }
def x-amz-target-completer-19 [] { ["Route53Domains_v20140515.ListTagsForDomain"] }
def x-amz-target-completer-20 [] { ["Route53Domains_v20140515.PushDomain"] }
def x-amz-target-completer-21 [] { ["Route53Domains_v20140515.RegisterDomain"] }
def x-amz-target-completer-22 [] { ["Route53Domains_v20140515.RejectDomainTransferFromAnotherAwsAccount"] }
def x-amz-target-completer-23 [] { ["Route53Domains_v20140515.RenewDomain"] }
def x-amz-target-completer-24 [] { ["Route53Domains_v20140515.ResendContactReachabilityEmail"] }
def x-amz-target-completer-25 [] { ["Route53Domains_v20140515.ResendOperationAuthorization"] }
def x-amz-target-completer-26 [] { ["Route53Domains_v20140515.RetrieveDomainAuthCode"] }
def x-amz-target-completer-27 [] { ["Route53Domains_v20140515.TransferDomain"] }
def x-amz-target-completer-28 [] { ["Route53Domains_v20140515.TransferDomainToAnotherAwsAccount"] }
def x-amz-target-completer-29 [] { ["Route53Domains_v20140515.UpdateDomainContact"] }
def x-amz-target-completer-30 [] { ["Route53Domains_v20140515.UpdateDomainContactPrivacy"] }
def x-amz-target-completer-31 [] { ["Route53Domains_v20140515.UpdateDomainNameservers"] }
def x-amz-target-completer-32 [] { ["Route53Domains_v20140515.UpdateTagsForDomain"] }
def x-amz-target-completer-33 [] { ["Route53Domains_v20140515.ViewBilling"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accept-domain-transfer-from-another-aws-account" } } | get name | first)
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

# Accepts the transfer of a domain from another Amazon Web Services account to the currentAmazon Web Services account. You initiate a transfer between Amazon Web Services accounts using TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html). If you use the CLI command at accept-domain-transfer-from-another-aws-account (https://docs.aws.amazon.com/cli/latest/reference/route53domains/accept-domain-transfer-from-another-aws-account.html), use JSON format as input instead of text because otherwise CLI will throw an error from domain transfer input that includes single quotes. Use either ListOperations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_ListOperations.html) or GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to determine whether the operation succeeded. GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) provides additional information, for example, Domain Transfer from Aws Account 111122223333 has been cancelled.
#
# POST /
# operationId: AcceptDomainTransferFromAnotherAwsAccount
export def "accept-domain-transfer-from-another-aws-account" [
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
  domain_name: string # The name of the domain that was specified when another Amazon Web Services account submitted a TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html) request.
  password: string # The password that was returned by the TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html) request.
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.AcceptDomainTransferFromAnotherAwsAccount")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "Password": $password} | compact
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

# Creates a delegation signer (DS) record in the registry zone for this domain name. Note that creating DS record at the registry impacts DNSSEC validation of your DNS records. This action may render your domain name unavailable on the internet if the steps are completed in the wrong order, or with incorrect timing. For more information about DNSSEC signing, see Configuring DNSSEC signing (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec.html) in the Route 53 developer guide.
#
# POST /
# operationId: AssociateDelegationSignerToDomain
# --SigningAttributes shape: {Algorithm?: int, Flags?: int, PublicKey?: string}
export def "associate-delegation-signer-to-domain" [
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
  domain_name: string # The name of the domain.
  signing_attributes: record # Information about a delegation signer (DS) record that was created in the registry by AssociateDelegationSignerToDomain (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_AssociateDelegationSignerToDomain.html). — shape: {Algorithm?: int, Flags?: int, PublicKey?: string}
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.AssociateDelegationSignerToDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "SigningAttributes": $signing_attributes} | compact
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

# Cancels the transfer of a domain from the current Amazon Web Services account to another Amazon Web Services account. You initiate a transfer betweenAmazon Web Services accounts using TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html). You must cancel the transfer before the other Amazon Web Services account accepts the transfer using AcceptDomainTransferFromAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_AcceptDomainTransferFromAnotherAwsAccount.html). Use either ListOperations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_ListOperations.html) or GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to determine whether the operation succeeded. GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) provides additional information, for example, Domain Transfer from Aws Account 111122223333 has been cancelled.
#
# POST /
# operationId: CancelDomainTransferToAnotherAwsAccount
export def "cancel-domain-transfer-to-another-aws-account" [
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
  domain_name: string # The name of the domain for which you want to cancel the transfer to another Amazon Web Services account.
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.CancelDomainTransferToAnotherAwsAccount")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# This operation checks the availability of one domain name. Note that if the availability status of a domain is pending, you must submit another request to determine the availability of the domain name.
#
# POST /
# operationId: CheckDomainAvailability
export def "check-domain-availability" [
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
  domain_name: string # The name of the domain that you want to get availability for. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com. Internationalized domain names are not supported for some top-level domains. To determine whether the TLD that you want to use supports internationalized domain names, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html). For more information, see Formatting Internationalized Domain Names (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html#domain-name-format-idns).
  --idn-lang-code: string # Reserved for future use.
]: any -> record<Availability: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.CheckDomainAvailability")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "IdnLangCode": $idn_lang_code} | compact
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

# Checks whether a domain name can be transferred to Amazon Route 53.
#
# POST /
# operationId: CheckDomainTransferability
export def "check-domain-transferability" [
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
  domain_name: string # The name of the domain that you want to transfer to Route 53. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com.
  --auth-code: string # If the registrar for the top-level domain (TLD) requires an authorization code to transfer the domain, the code that you got from the current registrar for the domain. (format: password)
]: any -> record<Transferability: record<Transferable: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.CheckDomainTransferability")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "AuthCode": $auth_code} | compact
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

# This operation deletes the specified domain. This action is permanent. For more information, see Deleting a domain name registration (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-delete.html). To transfer the domain registration to another registrar, use the transfer process that’s provided by the registrar to which you want to transfer the registration. Otherwise, the following apply: You can’t get a refund for the cost of a deleted domain registration. The registry for the top-level domain might hold the domain name for a brief time before releasing it for other users to register (varies by registry). When the registration has been deleted, we'll send you a confirmation to the registrant contact. The email will come from noreply@domainnameverification.net or noreply@registrar.amazon.com.
#
# POST /
# operationId: DeleteDomain
export def "delete-domain" [
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
  domain_name: string # Name of the domain to be deleted.
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.DeleteDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# This operation deletes the specified tags for a domain. All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.
#
# POST /
# operationId: DeleteTagsForDomain
export def "delete-tags-for-domain" [
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
  domain_name: string # The domain for which you want to delete one or more tags.
  tags_to_delete: list<string> # A list of tag keys to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.DeleteTagsForDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "TagsToDelete": $tags_to_delete} | compact
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

# This operation disables automatic renewal of domain registration for the specified domain.
#
# POST /
# operationId: DisableDomainAutoRenew
export def "disable-domain-auto-renew" [
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
  domain_name: string # The name of the domain that you want to disable automatic renewal for.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.DisableDomainAutoRenew")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# This operation removes the transfer lock on the domain (specifically the clientTransferProhibited status) to allow domain transfers. We recommend you refrain from performing this action unless you intend to transfer the domain to a different registrar. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
#
# POST /
# operationId: DisableDomainTransferLock
export def "disable-domain-transfer-lock" [
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
  domain_name: string # The name of the domain that you want to remove the transfer lock for.
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.DisableDomainTransferLock")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# Deletes a delegation signer (DS) record in the registry zone for this domain name.
#
# POST /
# operationId: DisassociateDelegationSignerFromDomain
export def "disassociate-delegation-signer-from-domain" [
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
  domain_name: string # Name of the domain.
  id: string # An internal identification number assigned to each DS record after it’s created. You can retrieve it as part of DNSSEC information returned by GetDomainDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetDomainDetail.html).
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.DisassociateDelegationSignerFromDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "Id": $id} | compact
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

# This operation configures Amazon Route 53 to automatically renew the specified domain before the domain registration expires. The cost of renewing your domain registration is billed to your Amazon Web Services account. The period during which you can renew a domain name varies by TLD. For a list of TLDs and their renewal policies, see Domains That You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. Route 53 requires that you renew before the end of the renewal period so we can complete processing before the deadline.
#
# POST /
# operationId: EnableDomainAutoRenew
export def "enable-domain-auto-renew" [
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
  domain_name: string # The name of the domain that you want to enable automatic renewal for.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.EnableDomainAutoRenew")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# This operation sets the transfer lock on the domain (specifically the clientTransferProhibited status) to prevent domain transfers. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
#
# POST /
# operationId: EnableDomainTransferLock
export def "enable-domain-transfer-lock" [
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
  domain_name: string # The name of the domain that you want to set the transfer lock for.
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.EnableDomainTransferLock")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation returns information about whether the registrant contact has responded. If you want us to resend the email, use the ResendContactReachabilityEmail operation.
#
# POST /
# operationId: GetContactReachabilityStatus
export def "get-contact-reachability-status" [
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
  --domain-name: string # The name of the domain for which you want to know whether the registrant contact has confirmed that the email address is valid.
]: any -> record<domainName: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.GetContactReachabilityStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domainName": $domain_name} | compact
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

# This operation returns detailed information about a specified domain that is associated with the current Amazon Web Services account. Contact information for the domain is also returned as part of the output.
#
# POST /
# operationId: GetDomainDetail
export def "get-domain-detail" [
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
  domain_name: string # The name of the domain that you want to get detailed information about.
]: any -> record<DomainName: string, Nameservers: table<Name: string, GlueIps: list>, AutoRenew: bool, AdminContact: record<FirstName: string, LastName: string, ContactType: string, OrganizationName: string, AddressLine1: string, AddressLine2: string, City: string, State: string, CountryCode: string, ZipCode: string, PhoneNumber: string, Email: string, Fax: string, ExtraParams: list<record>>, RegistrantContact: record<FirstName: string, LastName: string, ContactType: string, OrganizationName: string, AddressLine1: string, AddressLine2: string, City: string, State: string, CountryCode: string, ZipCode: string, PhoneNumber: string, Email: string, Fax: string, ExtraParams: list<record>>, TechContact: record<FirstName: string, LastName: string, ContactType: string, OrganizationName: string, AddressLine1: string, AddressLine2: string, City: string, State: string, CountryCode: string, ZipCode: string, PhoneNumber: string, Email: string, Fax: string, ExtraParams: list<record>>, AdminPrivacy: bool, RegistrantPrivacy: bool, TechPrivacy: bool, RegistrarName: string, WhoIsServer: string, RegistrarUrl: string, AbuseContactEmail: string, AbuseContactPhone: string, RegistryDomainId: string, CreationDate: string, UpdatedDate: string, ExpirationDate: string, Reseller: string, DnsSec: string, StatusList: list<string>, DnssecKeys: table<Algorithm: int, Flags: int, PublicKey: string, DigestType: int, Digest: string, KeyTag: int, Id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.GetDomainDetail")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# The GetDomainSuggestions operation returns a list of suggested domain names.
#
# POST /
# operationId: GetDomainSuggestions
export def "get-domain-suggestions" [
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
  domain_name: string # A domain name that you want to use as the basis for a list of possible domain names. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com. Internationalized domain names are not supported for some top-level domains. To determine whether the TLD that you want to use supports internationalized domain names, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html).
  suggestion_count: int # The number of suggested domain names that you want Route 53 to return. Specify a value between 1 and 50.
  --only-available: oneof<nothing, bool> # If OnlyAvailable is true, Route 53 returns only domain names that are available. If OnlyAvailable is false, Route 53 returns domain names without checking whether they're available to be registered. To determine whether the domain is available, you can call checkDomainAvailability for each suggestion.
]: any -> record<SuggestionsList: table<DomainName: string, Availability: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.GetDomainSuggestions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "SuggestionCount": $suggestion_count, "OnlyAvailable": $only_available} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "OnlyAvailable") == null) { error make --unspanned { msg: "required body field 'OnlyAvailable' missing: pass --only-available or pipe a record" } }
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

# This operation returns the current status of an operation that is not completed.
#
# POST /
# operationId: GetOperationDetail
export def "get-operation-detail" [
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
  operation_id: string # The identifier for the operation for which you want to get the status. Route 53 returned the identifier in the response to the original request.
]: any -> record<OperationId: string, Status: string, Message: string, DomainName: string, Type: string, SubmittedDate: string, LastUpdatedDate: string, StatusFlag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.GetOperationDetail")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OperationId": $operation_id} | compact
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

# This operation returns all the domain names registered with Amazon Route 53 for the current Amazon Web Services account if no filtering conditions are used.
#
# POST /
# operationId: ListDomains
# --FilterConditions item shape: {Name: "DomainName"|"Expiry", Operator: "LE"|"GE"|"BEGINS_WITH", Values: list<string>}
# --SortCondition shape: {Name: "DomainName"|"Expiry", SortOrder: "ASC"|"DESC"}
export def "list-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  --filter-conditions: list # A complex type that contains information about the filters applied during the ListDomains request. The filter conditions can include domain name and domain expiration. — item shape: {Name: "DomainName"|"Expiry", Operator: "LE"|"GE"|"BEGINS_WITH", Values: list<string>}
  --sort-condition: record # Information for sorting a list of domains. — shape: {Name: "DomainName"|"Expiry", SortOrder: "ASC"|"DESC"}
  --marker-body: string # For an initial request for a list of domains, omit this element. If the number of domains that are associated with the current Amazon Web Services account is greater than the value that you specified for MaxItems, you can use Marker to return additional domains. Get the value of NextPageMarker from the previous response, and submit another request that includes the value of NextPageMarker in the Marker element. Constraints: The marker must match the value specified in the previous request. (body field)
  --max-items-body: int # Number of domains to be returned. Default: 20 (body field)
]: any -> record<Domains: table<DomainName: string, AutoRenew: bool, TransferLock: bool, Expiry: string>, NextPageMarker: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.ListDomains")
  let qp = [(serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FilterConditions": $filter_conditions, "SortCondition": $sort_condition, "Marker": $marker_body, "MaxItems": $max_items_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxItems": $max_items, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about all of the operations that return an operation ID and that have ever been performed on domains that were registered by the current account. This command runs only in the us-east-1 Region.
#
# POST /
# operationId: ListOperations
export def "list-operations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  --submitted-since: string # An optional parameter that lets you get information about all the operations that you submitted after a specified date and time. Specify the date and time in Unix time format and Coordinated Universal time (UTC). (format: date-time)
  --marker-body: string # For an initial request for a list of operations, omit this element. If the number of operations that are not yet complete is greater than the value that you specified for MaxItems, you can use Marker to return additional operations. Get the value of NextPageMarker from the previous response, and submit another request that includes the value of NextPageMarker in the Marker element. (body field)
  --max-items-body: int # Number of domains to be returned. Default: 20 (body field)
  --status: list<string> # The status of the operations.
  --type: list<string> # An arrays of the domains operation types.
  --sort-by: string@sort-by-completer # The sort type for returned values.
  --sort-order: string@sort-order-completer # The sort order ofr returned values, either ascending or descending.
]: any -> record<Operations: table<OperationId: string, Status: string, Type: string, SubmittedDate: string, DomainName: string, Message: string, StatusFlag: string, LastUpdatedDate: string>, NextPageMarker: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.ListOperations")
  let qp = [(serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"SubmittedSince": $submitted_since, "Marker": $marker_body, "MaxItems": $max_items_body, "Status": $status, "Type": $type, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxItems": $max_items, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the following prices for either all the TLDs supported by Route 53, or the specified TLD: Registration Transfer Owner change Domain renewal Domain restoration
#
# POST /
# operationId: ListPrices
export def "list-prices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  --tld: string # The TLD for which you want to receive the pricing information. For example. .net. If a Tld value is not provided, a list of prices for all TLDs supported by Route 53 is returned.
  --marker-body: string # For an initial request for a list of prices, omit this element. If the number of prices that are not yet complete is greater than the value that you specified for MaxItems, you can use Marker to return additional prices. Get the value of NextPageMarker from the previous response, and submit another request that includes the value of NextPageMarker in the Marker element. Used only for all TLDs. If you specify a TLD, don't specify a Marker. (body field)
  --max-items-body: int # Number of Prices to be returned. Used only for all TLDs. If you specify a TLD, don't specify a MaxItems. (body field)
]: any -> record<Prices: table<Name: string, RegistrationPrice: record, TransferPrice: record, RenewalPrice: record, ChangeOwnershipPrice: record, RestorationPrice: record>, NextPageMarker: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.ListPrices")
  let qp = [(serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Tld": $tld, "Marker": $marker_body, "MaxItems": $max_items_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxItems": $max_items, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation returns all of the tags that are associated with the specified domain. All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.
#
# POST /
# operationId: ListTagsForDomain
export def "list-tags-for-domain" [
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
  domain_name: string # The domain for which you want to get a list of tags.
]: any -> record<TagList: table<Key: string, Value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.ListTagsForDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# Moves a domain from Amazon Web Services to another registrar. Supported actions: Changes the IPS tags of a .uk domain, and pushes it to transit. Transit means that the domain is ready to be transferred to another registrar.
#
# POST /
# operationId: PushDomain
export def "push-domain" [
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
  domain_name: string # Name of the domain.
  target: string # New IPS tag for the domain.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.PushDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "Target": $target} | compact
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

# This operation registers a domain. Domains are registered either by Amazon Registrar (for .com, .net, and .org domains) or by our registrar associate, Gandi (for all other domains). For some top-level domains (TLDs), this operation requires extra parameters. When you register a domain, Amazon Route 53 does the following: Creates a Route 53 hosted zone that has the same name as the domain. Route 53 assigns four name servers to your hosted zone and automatically updates your domain registration with the names of these name servers. Enables auto renew, so your domain registration will renew automatically each year. We'll notify you in advance of the renewal date so you can choose whether to renew the registration. Optionally enables privacy protection, so WHOIS queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you don't enable privacy protection, WHOIS queries return the information that you entered for the administrative, registrant, and technical contacts. You must specify the same privacy setting for the administrative, registrant, and technical contacts. If registration is successful, returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant is notified by email. Charges your Amazon Web Services account an amount based on the top-level domain. For more information, see Amazon Route 53 Pricing (http://aws.amazon.com/route53/pricing/).
#
# POST /
# operationId: RegisterDomain
# --AdminContact shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
# --RegistrantContact shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
# --TechContact shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
export def "register-domain" [
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
  domain_name: string # The domain name that you want to register. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com. Internationalized domain names are not supported for some top-level domains. To determine whether the TLD that you want to use supports internationalized domain names, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html). For more information, see Formatting Internationalized Domain Names (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html#domain-name-format-idns).
  --idn-lang-code: string # Reserved for future use.
  duration_in_years: int # The number of years that you want to register the domain for. Domains are registered for a minimum of one year. The maximum period depends on the top-level domain. For the range of valid values for your domain, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. Default: 1
  --auto-renew: oneof<nothing, bool> # Indicates whether the domain will be automatically renewed (true) or not (false). Auto renewal only takes effect after the account is charged. Default: true
  admin_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  registrant_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  tech_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --privacy-protect-admin-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the admin contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
  --privacy-protect-registrant-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the registrant contact (the domain owner). You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
  --privacy-protect-tech-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the technical contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.RegisterDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "IdnLangCode": $idn_lang_code, "DurationInYears": $duration_in_years, "AutoRenew": $auto_renew, "AdminContact": $admin_contact, "RegistrantContact": $registrant_contact, "TechContact": $tech_contact, "PrivacyProtectAdminContact": $privacy_protect_admin_contact, "PrivacyProtectRegistrantContact": $privacy_protect_registrant_contact, "PrivacyProtectTechContact": $privacy_protect_tech_contact} | compact
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

# Rejects the transfer of a domain from another Amazon Web Services account to the current Amazon Web Services account. You initiate a transfer betweenAmazon Web Services accounts using TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html). Use either ListOperations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_ListOperations.html) or GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to determine whether the operation succeeded. GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) provides additional information, for example, Domain Transfer from Aws Account 111122223333 has been cancelled.
#
# POST /
# operationId: RejectDomainTransferFromAnotherAwsAccount
export def "reject-domain-transfer-from-another-aws-account" [
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
  domain_name: string # The name of the domain that was specified when another Amazon Web Services account submitted a TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html) request.
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.RejectDomainTransferFromAnotherAwsAccount")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# This operation renews a domain for the specified number of years. The cost of renewing your domain is billed to your Amazon Web Services account. We recommend that you renew your domain several weeks before the expiration date. Some TLD registries delete domains before the expiration date if you haven't renewed far enough in advance. For more information about renewing domain registration, see Renewing Registration for a Domain (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-renew.html) in the Amazon Route 53 Developer Guide.
#
# POST /
# operationId: RenewDomain
export def "renew-domain" [
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
  domain_name: string # The name of the domain that you want to renew.
  --duration-in-years: int # The number of years that you want to renew the domain for. The maximum number of years depends on the top-level domain. For the range of valid values for your domain, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. Default: 1
  current_expiry_year: int # The year when the registration for the domain is set to expire. This value must match the current expiration date for the domain.
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.RenewDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "DurationInYears": $duration_in_years, "CurrentExpiryYear": $current_expiry_year} | compact
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

# For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation resends the confirmation email to the current email address for the registrant contact.
#
# POST /
# operationId: ResendContactReachabilityEmail
export def "resend-contact-reachability-email" [
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
  --domain-name: string # The name of the domain for which you want Route 53 to resend a confirmation email to the registrant contact.
]: any -> record<domainName: string, emailAddress: string, isAlreadyVerified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.ResendContactReachabilityEmail")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"domainName": $domain_name} | compact
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

# Resend the form of authorization email for this operation.
#
# POST /
# operationId: ResendOperationAuthorization
export def "resend-operation-authorization" [
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
  operation_id: string # Operation ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.ResendOperationAuthorization")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OperationId": $operation_id} | compact
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

# This operation returns the authorization code for the domain. To transfer a domain to another registrar, you provide this value to the new registrar.
#
# POST /
# operationId: RetrieveDomainAuthCode
export def "retrieve-domain-auth-code" [
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
  domain_name: string # The name of the domain that you want to get an authorization code for.
]: any -> record<AuthCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.RetrieveDomainAuthCode")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
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

# Transfers a domain from another registrar to Amazon Route 53. When the transfer is complete, the domain is registered either with Amazon Registrar (for .com, .net, and .org domains) or with our registrar associate, Gandi (for all other TLDs). For more information about transferring domains, see the following topics: For transfer requirements, a detailed procedure, and information about viewing the status of a domain that you're transferring to Route 53, see Transferring Registration for a Domain to Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-to-route-53.html) in the Amazon Route 53 Developer Guide. For information about how to transfer a domain from one Amazon Web Services account to another, see TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html). For information about how to transfer a domain to another domain registrar, see Transferring a Domain from Amazon Route 53 to Another Registrar (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-from-route-53.html) in the Amazon Route 53 Developer Guide. If the registrar for your domain is also the DNS service provider for the domain, we highly recommend that you transfer your DNS service to Route 53 or to another DNS service provider before you transfer your registration. Some registrars provide free DNS service when you purchase a domain registration. When you transfer the registration, the previous registrar will not renew your domain registration and could end your DNS service at any time. If the registrar for your domain is also the DNS service provider for the domain and you don't transfer DNS service to another provider, your website, email, and the web applications associated with the domain might become unavailable. If the transfer is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the transfer doesn't complete successfully, the domain registrant will be notified by email.
#
# POST /
# operationId: TransferDomain
# --Nameservers item shape: {Name: string, GlueIps?: list<string>}
# --AdminContact shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
# --RegistrantContact shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
# --TechContact shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
export def "transfer-domain" [
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
  domain_name: string # The name of the domain that you want to transfer to Route 53. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com.
  --idn-lang-code: string # Reserved for future use.
  duration_in_years: int # The number of years that you want to register the domain for. Domains are registered for a minimum of one year. The maximum period depends on the top-level domain. Default: 1
  --nameservers: list # Contains details for the host and glue IP addresses. — item shape: {Name: string, GlueIps?: list<string>}
  --auth-code: string # The authorization code for the domain. You get this value from the current registrar. (format: password)
  --auto-renew: oneof<nothing, bool> # Indicates whether the domain will be automatically renewed (true) or not (false). Auto renewal only takes effect after the account is charged. Default: true
  admin_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  registrant_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  tech_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --privacy-protect-admin-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the admin contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
  --privacy-protect-registrant-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the registrant contact (domain owner). You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
  --privacy-protect-tech-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the technical contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.TransferDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "IdnLangCode": $idn_lang_code, "DurationInYears": $duration_in_years, "Nameservers": $nameservers, "AuthCode": $auth_code, "AutoRenew": $auto_renew, "AdminContact": $admin_contact, "RegistrantContact": $registrant_contact, "TechContact": $tech_contact, "PrivacyProtectAdminContact": $privacy_protect_admin_contact, "PrivacyProtectRegistrantContact": $privacy_protect_registrant_contact, "PrivacyProtectTechContact": $privacy_protect_tech_contact} | compact
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

# Transfers a domain from the current Amazon Web Services account to another Amazon Web Services account. Note the following: The Amazon Web Services account that you're transferring the domain to must accept the transfer. If the other account doesn't accept the transfer within 3 days, we cancel the transfer. See AcceptDomainTransferFromAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_AcceptDomainTransferFromAnotherAwsAccount.html). You can cancel the transfer before the other account accepts it. See CancelDomainTransferToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_CancelDomainTransferToAnotherAwsAccount.html). The other account can reject the transfer. See RejectDomainTransferFromAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_RejectDomainTransferFromAnotherAwsAccount.html). When you transfer a domain from one Amazon Web Services account to another, Route 53 doesn't transfer the hosted zone that is associated with the domain. DNS resolution isn't affected if the domain and the hosted zone are owned by separate accounts, so transferring the hosted zone is optional. For information about transferring the hosted zone to another Amazon Web Services account, see Migrating a Hosted Zone to a Different Amazon Web Services Account (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-migrating.html) in the Amazon Route 53 Developer Guide. Use either ListOperations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_ListOperations.html) or GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to determine whether the operation succeeded. GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) provides additional information, for example, Domain Transfer from Aws Account 111122223333 has been cancelled.
#
# POST /
# operationId: TransferDomainToAnotherAwsAccount
export def "transfer-domain-to-another-aws-account" [
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
  domain_name: string # The name of the domain that you want to transfer from the current Amazon Web Services account to another account.
  account_id: string # The account ID of the Amazon Web Services account that you want to transfer the domain to, for example, 111122223333.
]: any -> record<OperationId: string, Password: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.TransferDomainToAnotherAwsAccount")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "AccountId": $account_id} | compact
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

# This operation updates the contact information for a particular domain. You must specify information for at least one contact: registrant, administrator, or technical. If the update is successful, this method returns an operation ID that you can use to track the progress and completion of the operation. If the request is not completed successfully, the domain registrant will be notified by email.
#
# POST /
# operationId: UpdateDomainContact
# --AdminContact shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
# --RegistrantContact shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
# --TechContact shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
# --Consent shape: {MaxPrice: float, Currency: string}
export def "update-domain-contact" [
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
  domain_name: string # The name of the domain that you want to update contact information for.
  --admin-contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --registrant-contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --tech-contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --consent: record # Customer's consent for the owner change request. — shape: {MaxPrice: float, Currency: string}
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.UpdateDomainContact")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "AdminContact": $admin_contact, "RegistrantContact": $registrant_contact, "TechContact": $tech_contact, "Consent": $consent} | compact
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

# This operation updates the specified domain contact's privacy setting. When privacy protection is enabled, contact information such as email address is replaced either with contact information for Amazon Registrar (for .com, .net, and .org domains) or with contact information for our registrar associate, Gandi. You must specify the same privacy setting for the administrative, registrant, and technical contacts. This operation affects only the contact information for the specified contact type (administrative, registrant, or technical). If the request succeeds, Amazon Route 53 returns an operation ID that you can use with GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to track the progress and completion of the action. If the request doesn't complete successfully, the domain registrant will be notified by email. By disabling the privacy service via API, you consent to the publication of the contact information provided for this domain via the public WHOIS database. You certify that you are the registrant of this domain name and have the authority to make this decision. You may withdraw your consent at any time by enabling privacy protection using either UpdateDomainContactPrivacy or the Route 53 console. Enabling privacy protection removes the contact information provided for this domain from the WHOIS database. For more information on our privacy practices, see https://aws.amazon.com/privacy/ (https://aws.amazon.com/privacy/).
#
# POST /
# operationId: UpdateDomainContactPrivacy
export def "update-domain-contact-privacy" [
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
  domain_name: string # The name of the domain that you want to update the privacy setting for.
  --admin-privacy: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the admin contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts.
  --registrant-privacy: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the registrant contact (domain owner). You must specify the same privacy setting for the administrative, registrant, and technical contacts.
  --tech-privacy: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the technical contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts.
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.UpdateDomainContactPrivacy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "AdminPrivacy": $admin_privacy, "RegistrantPrivacy": $registrant_privacy, "TechPrivacy": $tech_privacy} | compact
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

# This operation replaces the current set of name servers for the domain with the specified set of name servers. If you use Amazon Route 53 as your DNS service, specify the four name servers in the delegation set for the hosted zone for the domain. If successful, this operation returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
#
# POST /
# operationId: UpdateDomainNameservers
# --Nameservers item shape: {Name: string, GlueIps?: list<string>}
export def "update-domain-nameservers" [
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
  domain_name: string # The name of the domain that you want to change name servers for.
  --fi-auth-key: string # The authorization key for .fi domains (format: password)
  nameservers: list # A list of new name servers for the domain. — item shape: {Name: string, GlueIps?: list<string>}
]: any -> record<OperationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.UpdateDomainNameservers")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "FIAuthKey": $fi_auth_key, "Nameservers": $nameservers} | compact
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

# This operation adds or updates tags for a specified domain. All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.
#
# POST /
# operationId: UpdateTagsForDomain
# --TagsToUpdate item shape: {Key?: string, Value?: string}
export def "update-tags-for-domain" [
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
  domain_name: string # The domain for which you want to add or update tags.
  --tags-to-update: list # A list of the tag keys and values that you want to add or update. If you specify a key that already exists, the corresponding value will be replaced. — item shape: {Key?: string, Value?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.UpdateTagsForDomain")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DomainName": $domain_name, "TagsToUpdate": $tags_to_update} | compact
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

# Returns all the domain-related billing records for the current Amazon Web Services account for a specified period
#
# POST /
# operationId: ViewBilling
export def "view-billing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  --start: string # The beginning date and time for the time period for which you want a list of billing records. Specify the date and time in Unix time format and Coordinated Universal time (UTC). (format: date-time)
  --end: string # The end date and time for the time period for which you want a list of billing records. Specify the date and time in Unix time format and Coordinated Universal time (UTC). (format: date-time)
  --marker-body: string # For an initial request for a list of billing records, omit this element. If the number of billing records that are associated with the current Amazon Web Services account during the specified period is greater than the value that you specified for MaxItems, you can use Marker to return additional billing records. Get the value of NextPageMarker from the previous response, and submit another request that includes the value of NextPageMarker in the Marker element. Constraints: The marker must match the value of NextPageMarker that was returned in the previous response. (body field)
  --max-items-body: int # The number of billing records to be returned. Default: 20 (body field)
]: any -> record<NextPageMarker: string, BillingRecords: table<DomainName: string, Operation: string, InvoiceId: string, BillDate: string, Price: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Route53Domains_v20140515.ViewBilling")
  let qp = [(serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Start": $start, "End": $end, "Marker": $marker_body, "MaxItems": $max_items_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxItems": $max_items, "Marker": $marker} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
