# Auto-generated client for Amazon Elasticsearch Service v2015-01-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/es/2015-01-01/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTICSEARCH_SERVICE_TOKEN

const BASE_URL = "http://es.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_ELASTICSEARCH_SERVICE_TOKEN | default "" }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://es.us-east-1.amazonaws.com" "http://es.us-east-2.amazonaws.com" "http://es.us-west-1.amazonaws.com" "http://es.us-west-2.amazonaws.com" "http://es.us-gov-west-1.amazonaws.com" "http://es.us-gov-east-1.amazonaws.com" "http://es.ca-central-1.amazonaws.com" "http://es.eu-north-1.amazonaws.com" "http://es.eu-west-1.amazonaws.com" "http://es.eu-west-2.amazonaws.com" "http://es.eu-west-3.amazonaws.com" "http://es.eu-central-1.amazonaws.com" "http://es.eu-south-1.amazonaws.com" "http://es.af-south-1.amazonaws.com" "http://es.ap-northeast-1.amazonaws.com" "http://es.ap-northeast-2.amazonaws.com" "http://es.ap-northeast-3.amazonaws.com" "http://es.ap-southeast-1.amazonaws.com" "http://es.ap-southeast-2.amazonaws.com" "http://es.ap-east-1.amazonaws.com" "http://es.ap-south-1.amazonaws.com" "http://es.sa-east-1.amazonaws.com" "http://es.me-south-1.amazonaws.com" "https://es.us-east-1.amazonaws.com" "https://es.us-east-2.amazonaws.com" "https://es.us-west-1.amazonaws.com" "https://es.us-west-2.amazonaws.com" "https://es.us-gov-west-1.amazonaws.com" "https://es.us-gov-east-1.amazonaws.com" "https://es.ca-central-1.amazonaws.com" "https://es.eu-north-1.amazonaws.com" "https://es.eu-west-1.amazonaws.com" "https://es.eu-west-2.amazonaws.com" "https://es.eu-west-3.amazonaws.com" "https://es.eu-central-1.amazonaws.com" "https://es.eu-south-1.amazonaws.com" "https://es.af-south-1.amazonaws.com" "https://es.ap-northeast-1.amazonaws.com" "https://es.ap-northeast-2.amazonaws.com" "https://es.ap-northeast-3.amazonaws.com" "https://es.ap-southeast-1.amazonaws.com" "https://es.ap-southeast-2.amazonaws.com" "https://es.ap-east-1.amazonaws.com" "https://es.ap-south-1.amazonaws.com" "https://es.sa-east-1.amazonaws.com" "https://es.me-south-1.amazonaws.com" "http://es.cn-north-1.amazonaws.com.cn" "http://es.cn-northwest-1.amazonaws.com.cn" "https://es.cn-north-1.amazonaws.com.cn" "https://es.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def package-type-completer [] { ["TXT-DICTIONARY"] }
def engine-type-completer [] { ["Elasticsearch" "OpenSearch"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2015-01-01-es-ccs-inbound-connection-accept list-cross" } } | get name | first)
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

# Allows the destination domain owner to accept an inbound cross-cluster search connection request.
#
# PUT /2015-01-01/es/ccs/inboundConnection/{ConnectionId}/accept
# operationId: AcceptInboundCrossClusterSearchConnection
export def "2015-01-01-es-ccs-inbound-connection-accept list-cross" [
  connection_id: string
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
]: nothing -> record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: record, ConnectionStatus: record<StatusCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'ConnectionId' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/2015-01-01/es/ccs/inboundConnection/{connection_id}/accept") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See Tagging Amazon Elasticsearch Service Domains for more information. (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging)
#
# POST /2015-01-01/tags
# operationId: AddTags
# --TagList item shape: {Key: any, Value: any}
export def "2015-01-01-tags create" [
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
  arn: string # The Amazon Resource Name (ARN) of the Elasticsearch domain. See Identifiers for IAM Entities (http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html) in Using AWS Identity and Access Management for more information.
  tag_list: list # A list of Tag — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/tags" $auth.query)
  let req_body = {"ARN": $arn, "TagList": $tag_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Associates a package with an Amazon ES domain.
#
# POST /2015-01-01/packages/associate/{PackageID}/{DomainName}
# operationId: AssociatePackage
export def "2015-01-01-packages-associate create" [
  package_id: string
  domain_name: string
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
]: nothing -> record<DomainPackageDetails: record<PackageID: record, PackageName: record, PackageType: record, LastUpdated: record, DomainName: record, DomainPackageStatus: record, PackageVersion: string, ReferencePath: record, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id), domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/packages/associate/{package_id}/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Provides access to an Amazon OpenSearch Service domain through the use of an interface VPC endpoint.
#
# POST /2015-01-01/es/domain/{DomainName}/authorizeVpcEndpointAccess
# operationId: AuthorizeVpcEndpointAccess
export def "2015-01-01-es-domain-authorize-vpc-endpoint-access create" [
  domain_name: string
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
  account: string # The account ID to grant access to.
]: any -> record<AuthorizedPrincipal: record<PrincipalType: record, Principal: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/authorizeVpcEndpointAccess") $auth.query)
  let req_body = {"Account": $account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the AutomatedUpdateDate and when the UpdateStatus is in the PENDING_UPDATE state.
#
# POST /2015-01-01/es/serviceSoftwareUpdate/cancel
# operationId: CancelElasticsearchServiceSoftwareUpdate
export def "2015-01-01-es-service-software-update-cancel cancel-elasticsearch" [
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
  domain_name: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
]: any -> record<ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/serviceSoftwareUpdate/cancel" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Creates a new Elasticsearch domain. For more information, see Creating Elasticsearch Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains) in the Amazon Elasticsearch Service Developer Guide.
#
# POST /2015-01-01/es/domain
# operationId: CreateElasticsearchDomain
# --ElasticsearchClusterConfig shape: {InstanceType?: any, InstanceCount?: any, DedicatedMasterEnabled?: any, ZoneAwarenessEnabled?: any, ZoneAwarenessConfig?: any, DedicatedMasterType?: any, DedicatedMasterCount?: any, WarmEnabled?: any, WarmType?: any, WarmCount?: any, ColdStorageOptions?: any}
# --EBSOptions shape: {EBSEnabled?: any, VolumeType?: any, VolumeSize?: any, Iops?: any, Throughput?: any}
# --SnapshotOptions shape: {AutomatedSnapshotStartHour?: any}
# --VPCOptions shape: {SubnetIds?: any, SecurityGroupIds?: any}
# --CognitoOptions shape: {Enabled?: any, UserPoolId?: any, IdentityPoolId?: any, RoleArn?: any}
# --EncryptionAtRestOptions shape: {Enabled?: any, KmsKeyId?: any}
# --NodeToNodeEncryptionOptions shape: {Enabled?: any}
# --DomainEndpointOptions shape: {EnforceHTTPS?: any, TLSSecurityPolicy?: any, CustomEndpointEnabled?: any, CustomEndpoint?: any, CustomEndpointCertificateArn?: any}
# --AdvancedSecurityOptions shape: {Enabled?: any, InternalUserDatabaseEnabled?: any, MasterUserOptions?: any, SAMLOptions?: any, AnonymousAuthEnabled?: any}
# --AutoTuneOptions shape: {DesiredState?: any, MaintenanceSchedules?: any}
# --TagList item shape: {Key: any, Value: any}
export def "2015-01-01-es-domain create-elasticsearch" [
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
  domain_name: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  --elasticsearch-version: string # String of format X.Y to specify version for the Elasticsearch domain eg. "1.5" or "2.3". For more information, see Creating Elasticsearch Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains) in the Amazon Elasticsearch Service Developer Guide.
  --elasticsearch-cluster-config: record # Specifies the configuration for the domain cluster, such as the type and number of instances. — shape: {InstanceType?: any, InstanceCount?: any, DedicatedMasterEnabled?: any, ZoneAwarenessEnabled?: any, ZoneAwarenessConfig?: any, DedicatedMasterType?: any, DedicatedMasterCount?: any, WarmEnabled?: any, WarmType?: any, WarmCount?: any, ColdStorageOptions?: any}
  --ebs-options: record # Options to enable, disable, and specify the properties of EBS storage volumes. For more information, see Configuring EBS-based Storage (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-ebs). — shape: {EBSEnabled?: any, VolumeType?: any, VolumeSize?: any, Iops?: any, Throughput?: any}
  --access-policies: string # Access policy rules for an Elasticsearch domain service endpoints. For more information, see Configuring Access Policies (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-access-policies) in the Amazon Elasticsearch Service Developer Guide. The maximum size of a policy document is 100 KB.
  --snapshot-options: record # Specifies the time, in UTC format, when the service takes a daily automated snapshot of the specified Elasticsearch domain. Default value is 0 hours. — shape: {AutomatedSnapshotStartHour?: any}
  --vpc-options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --cognito-options: record # Options to specify the Cognito user and identity pools for Kibana authentication. For more information, see Amazon Cognito Authentication for Kibana (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-cognito-auth.html). — shape: {Enabled?: any, UserPoolId?: any, IdentityPoolId?: any, RoleArn?: any}
  --encryption-at-rest-options: record # Specifies the Encryption At Rest Options. — shape: {Enabled?: any, KmsKeyId?: any}
  --node-to-node-encryption-options: record # Specifies the node-to-node encryption options. — shape: {Enabled?: any}
  --advanced-options: record # Exposes select native Elasticsearch configuration values from elasticsearch.yml. Currently, the following advanced options are available: Option to allow references to indices in an HTTP request body. Must be false when configuring access to individual sub-resources. By default, the value is true. See Configuration Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options) for more information. Option to specify the percentage of heap space that is allocated to field data. By default, this setting is unbounded. For more information, see Configuring Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options).
  --log-publishing-options: record # Map of LogType and LogPublishingOption, each containing options to publish a given type of Elasticsearch log.
  --domain-endpoint-options: record # Options to configure endpoint for the Elasticsearch domain. — shape: {EnforceHTTPS?: any, TLSSecurityPolicy?: any, CustomEndpointEnabled?: any, CustomEndpoint?: any, CustomEndpointCertificateArn?: any}
  --advanced-security-options: record # Specifies the advanced security configuration: whether advanced security is enabled, whether the internal database option is enabled, master username and password (if internal database is enabled), and master user ARN (if IAM is enabled). — shape: {Enabled?: any, InternalUserDatabaseEnabled?: any, MasterUserOptions?: any, SAMLOptions?: any, AnonymousAuthEnabled?: any}
  --auto-tune-options: record # Specifies the Auto-Tune options: the Auto-Tune desired state for the domain and list of maintenance schedules. — shape: {DesiredState?: any, MaintenanceSchedules?: any}
  --tag-list: list # A list of Tag — item shape: {Key: any, Value: any}
]: any -> record<DomainStatus: record<DomainId: record, DomainName: record, ARN: record, Created: record, Deleted: record, Endpoint: record, Endpoints: record, Processing: record, UpgradeProcessing: record, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: record, InstanceCount: record, DedicatedMasterEnabled: record, ZoneAwarenessEnabled: record, ZoneAwarenessConfig: record, DedicatedMasterType: record, DedicatedMasterCount: record, WarmEnabled: record, WarmType: record, WarmCount: record, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: record, VolumeType: record, VolumeSize: record, Iops: record, Throughput: record>, AccessPolicies: record, SnapshotOptions: record<AutomatedSnapshotStartHour: record>, VPCOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, CognitoOptions: record<Enabled: record, UserPoolId: record, IdentityPoolId: record, RoleArn: record>, EncryptionAtRestOptions: record<Enabled: record, KmsKeyId: record>, NodeToNodeEncryptionOptions: record<Enabled: record>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>, DomainEndpointOptions: record<EnforceHTTPS: record, TLSSecurityPolicy: record, CustomEndpointEnabled: record, CustomEndpoint: record, CustomEndpointCertificateArn: record>, AdvancedSecurityOptions: record<Enabled: record, InternalUserDatabaseEnabled: record, SAMLOptions: record, AnonymousAuthDisableDate: record, AnonymousAuthEnabled: record>, AutoTuneOptions: record<State: record, ErrorMessage: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/domain" $auth.query)
  let req_body = {"DomainName": $domain_name, "ElasticsearchVersion": $elasticsearch_version, "ElasticsearchClusterConfig": $elasticsearch_cluster_config, "EBSOptions": $ebs_options, "AccessPolicies": $access_policies, "SnapshotOptions": $snapshot_options, "VPCOptions": $vpc_options, "CognitoOptions": $cognito_options, "EncryptionAtRestOptions": $encryption_at_rest_options, "NodeToNodeEncryptionOptions": $node_to_node_encryption_options, "AdvancedOptions": $advanced_options, "LogPublishingOptions": $log_publishing_options, "DomainEndpointOptions": $domain_endpoint_options, "AdvancedSecurityOptions": $advanced_security_options, "AutoTuneOptions": $auto_tune_options, "TagList": $tag_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Creates a new cross-cluster search connection from a source domain to a destination domain.
#
# POST /2015-01-01/es/ccs/outboundConnection
# operationId: CreateOutboundCrossClusterSearchConnection
# --SourceDomainInfo shape: {OwnerId?: string, DomainName?: string, Region?: string}
# --DestinationDomainInfo shape: {OwnerId?: string, DomainName?: string, Region?: string}
export def "2015-01-01-es-ccs-outbound-connection create-cross-list" [
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
  source_domain_info: record # Specifies the DomainInformation for the source Elasticsearch domain. — shape: {OwnerId?: string, DomainName?: string, Region?: string}
  destination_domain_info: record # Specifies the DomainInformation for the destination Elasticsearch domain. — shape: {OwnerId?: string, DomainName?: string, Region?: string}
  connection_alias: string # Specifies the connection alias that will be used by the customer for this connection.
]: any -> record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, ConnectionAlias: record, ConnectionStatus: record<StatusCode: record, Message: record>, CrossClusterSearchConnectionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/ccs/outboundConnection" $auth.query)
  let req_body = {"SourceDomainInfo": $source_domain_info, "DestinationDomainInfo": $destination_domain_info, "ConnectionAlias": $connection_alias} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Create a package for use with Amazon ES domains.
#
# POST /2015-01-01/packages
# operationId: CreatePackage
# --PackageSource shape: {S3BucketName?: any, S3Key?: any}
export def "2015-01-01-packages create" [
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
  package_name: string # Unique identifier for the package.
  package_type: string@package-type-completer # Type of package. Currently supports only TXT-DICTIONARY.
  --package-description: string # Description of the package.
  package_source: record # The S3 location for importing the package specified as S3BucketName and S3Key — shape: {S3BucketName?: any, S3Key?: any}
]: any -> record<PackageDetails: record<PackageID: record, PackageName: record, PackageType: record, PackageDescription: record, PackageStatus: record, CreatedAt: record, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/packages" $auth.query)
  let req_body = {"PackageName": $package_name, "PackageType": $package_type, "PackageDescription": $package_description, "PackageSource": $package_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Creates an Amazon OpenSearch Service-managed VPC endpoint.
#
# POST /2015-01-01/es/vpcEndpoints
# operationId: CreateVpcEndpoint
# --VpcOptions shape: {SubnetIds?: any, SecurityGroupIds?: any}
export def "2015-01-01-es-vpc-endpoints create" [
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
  domain_arn: string # The Amazon Resource Name (ARN) of the domain to grant access to.
  vpc_options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --client-token: string # Unique, case-sensitive identifier to ensure idempotency of the request.
]: any -> record<VpcEndpoint: record<VpcEndpointId: record, VpcEndpointOwner: record, DomainArn: record, VpcOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, Status: record, Endpoint: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints" $auth.query)
  let req_body = {"DomainArn": $domain_arn, "VpcOptions": $vpc_options, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Retrieves all Amazon OpenSearch Service-managed VPC endpoints in the current account and Region.
#
# GET /2015-01-01/es/vpcEndpoints
# operationId: ListVpcEndpoints
export def "2015-01-01-es-vpc-endpoints list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Identifier to allow retrieval of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<VpcEndpointSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
#
# DELETE /2015-01-01/es/domain/{DomainName}
# operationId: DeleteElasticsearchDomain
export def "2015-01-01-es-domain delete-elasticsearch" [
  domain_name: string
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
]: nothing -> record<DomainStatus: record<DomainId: record, DomainName: record, ARN: record, Created: record, Deleted: record, Endpoint: record, Endpoints: record, Processing: record, UpgradeProcessing: record, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: record, InstanceCount: record, DedicatedMasterEnabled: record, ZoneAwarenessEnabled: record, ZoneAwarenessConfig: record, DedicatedMasterType: record, DedicatedMasterCount: record, WarmEnabled: record, WarmType: record, WarmCount: record, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: record, VolumeType: record, VolumeSize: record, Iops: record, Throughput: record>, AccessPolicies: record, SnapshotOptions: record<AutomatedSnapshotStartHour: record>, VPCOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, CognitoOptions: record<Enabled: record, UserPoolId: record, IdentityPoolId: record, RoleArn: record>, EncryptionAtRestOptions: record<Enabled: record, KmsKeyId: record>, NodeToNodeEncryptionOptions: record<Enabled: record>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>, DomainEndpointOptions: record<EnforceHTTPS: record, TLSSecurityPolicy: record, CustomEndpointEnabled: record, CustomEndpoint: record, CustomEndpointCertificateArn: record>, AdvancedSecurityOptions: record<Enabled: record, InternalUserDatabaseEnabled: record, SAMLOptions: record, AnonymousAuthDisableDate: record, AnonymousAuthEnabled: record>, AutoTuneOptions: record<State: record, ErrorMessage: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
#
# GET /2015-01-01/es/domain/{DomainName}
# operationId: DescribeElasticsearchDomain
export def "2015-01-01-es-domain get-elasticsearch" [
  domain_name: string
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
]: nothing -> record<DomainStatus: record<DomainId: record, DomainName: record, ARN: record, Created: record, Deleted: record, Endpoint: record, Endpoints: record, Processing: record, UpgradeProcessing: record, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: record, InstanceCount: record, DedicatedMasterEnabled: record, ZoneAwarenessEnabled: record, ZoneAwarenessConfig: record, DedicatedMasterType: record, DedicatedMasterCount: record, WarmEnabled: record, WarmType: record, WarmCount: record, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: record, VolumeType: record, VolumeSize: record, Iops: record, Throughput: record>, AccessPolicies: record, SnapshotOptions: record<AutomatedSnapshotStartHour: record>, VPCOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, CognitoOptions: record<Enabled: record, UserPoolId: record, IdentityPoolId: record, RoleArn: record>, EncryptionAtRestOptions: record<Enabled: record, KmsKeyId: record>, NodeToNodeEncryptionOptions: record<Enabled: record>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>, DomainEndpointOptions: record<EnforceHTTPS: record, TLSSecurityPolicy: record, CustomEndpointEnabled: record, CustomEndpoint: record, CustomEndpointCertificateArn: record>, AdvancedSecurityOptions: record<Enabled: record, InternalUserDatabaseEnabled: record, SAMLOptions: record, AnonymousAuthDisableDate: record, AnonymousAuthEnabled: record>, AutoTuneOptions: record<State: record, ErrorMessage: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See Deleting Elasticsearch Service Role (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr) in VPC Endpoints for Amazon Elasticsearch Service Domains.
#
# DELETE /2015-01-01/es/role
# operationId: DeleteElasticsearchServiceRole
export def "2015-01-01-es-role delete-elasticsearch-service" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/role" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Allows the destination domain owner to delete an existing inbound cross-cluster search connection.
#
# DELETE /2015-01-01/es/ccs/inboundConnection/{ConnectionId}
# operationId: DeleteInboundCrossClusterSearchConnection
export def "2015-01-01-es-ccs-inbound-connection delete-cross-list" [
  connection_id: string
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
]: nothing -> record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: record, ConnectionStatus: record<StatusCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'ConnectionId' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/2015-01-01/es/ccs/inboundConnection/{connection_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Allows the source domain owner to delete an existing outbound cross-cluster search connection.
#
# DELETE /2015-01-01/es/ccs/outboundConnection/{ConnectionId}
# operationId: DeleteOutboundCrossClusterSearchConnection
export def "2015-01-01-es-ccs-outbound-connection delete-cross-list" [
  connection_id: string
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
]: nothing -> record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: record, ConnectionAlias: record, ConnectionStatus: record<StatusCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'ConnectionId' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/2015-01-01/es/ccs/outboundConnection/{connection_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Delete the package.
#
# DELETE /2015-01-01/packages/{PackageID}
# operationId: DeletePackage
export def "2015-01-01-packages delete" [
  package_id: string
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
]: nothing -> record<PackageDetails: record<PackageID: record, PackageName: record, PackageType: record, PackageDescription: record, PackageStatus: record, CreatedAt: record, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/2015-01-01/packages/{package_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Deletes an Amazon OpenSearch Service-managed interface VPC endpoint.
#
# DELETE /2015-01-01/es/vpcEndpoints/{VpcEndpointId}
# operationId: DeleteVpcEndpoint
export def "2015-01-01-es-vpc-endpoints delete" [
  vpc_endpoint_id: string
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
]: nothing -> record<VpcEndpointSummary: record<VpcEndpointId: record, VpcEndpointOwner: record, DomainArn: record, Status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_endpoint_id | is-empty) { error make --unspanned { msg: "path parameter 'VpcEndpointId' must be non-empty" } }
  let full_url = (build-url $base ({vpc_endpoint_id: (encode-path-segment $vpc_endpoint_id)} | format pattern "/2015-01-01/es/vpcEndpoints/{vpc_endpoint_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Provides scheduled Auto-Tune action details for the Elasticsearch domain, such as Auto-Tune action type, description, severity, and scheduled date.
#
# GET /2015-01-01/es/domain/{DomainName}/autoTunes
# operationId: DescribeDomainAutoTunes
export def "2015-01-01-es-domain-auto-tunes get" [
  domain_name: string
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
]: nothing -> record<AutoTunes: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/autoTunes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about the current blue/green deployment happening on a domain, including a change ID, status, and progress stages.
#
# GET /2015-01-01/es/domain/{DomainName}/progress
# operationId: DescribeDomainChangeProgress
export def "2015-01-01-es-domain-progress get-change" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --changeid: string # The specific change ID for which you want to get progress information. This is an optional parameter. If omitted, the service returns information about the most recent configuration change.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ChangeProgressStatus: record<ChangeId: record, StartTime: record, Status: record, PendingProperties: record, CompletedProperties: record, TotalNumberOfStages: record, ChangeProgressStages: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "changeid" $changeid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/progress") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"changeid": $changeid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
#
# GET /2015-01-01/es/domain/{DomainName}/config
# operationId: DescribeElasticsearchDomainConfig
export def "2015-01-01-es-domain-config get-elasticsearch" [
  domain_name: string
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
]: nothing -> record<DomainConfig: record<ElasticsearchVersion: record<Options: record, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: record, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/config") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances.
#
# POST /2015-01-01/es/domain/{DomainName}/config
# operationId: UpdateElasticsearchDomainConfig
# --ElasticsearchClusterConfig shape: {InstanceType?: any, InstanceCount?: any, DedicatedMasterEnabled?: any, ZoneAwarenessEnabled?: any, ZoneAwarenessConfig?: any, DedicatedMasterType?: any, DedicatedMasterCount?: any, WarmEnabled?: any, WarmType?: any, WarmCount?: any, ColdStorageOptions?: any}
# --EBSOptions shape: {EBSEnabled?: any, VolumeType?: any, VolumeSize?: any, Iops?: any, Throughput?: any}
# --SnapshotOptions shape: {AutomatedSnapshotStartHour?: any}
# --VPCOptions shape: {SubnetIds?: any, SecurityGroupIds?: any}
# --CognitoOptions shape: {Enabled?: any, UserPoolId?: any, IdentityPoolId?: any, RoleArn?: any}
# --DomainEndpointOptions shape: {EnforceHTTPS?: any, TLSSecurityPolicy?: any, CustomEndpointEnabled?: any, CustomEndpoint?: any, CustomEndpointCertificateArn?: any}
# --AdvancedSecurityOptions shape: {Enabled?: any, InternalUserDatabaseEnabled?: any, MasterUserOptions?: any, SAMLOptions?: any, AnonymousAuthEnabled?: any}
# --NodeToNodeEncryptionOptions shape: {Enabled?: any}
# --EncryptionAtRestOptions shape: {Enabled?: any, KmsKeyId?: any}
# --AutoTuneOptions shape: {DesiredState?: any, RollbackOnDisable?: any, MaintenanceSchedules?: any}
export def "2015-01-01-es-domain-config update-elasticsearch" [
  domain_name: string
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
  --elasticsearch-cluster-config: record # Specifies the configuration for the domain cluster, such as the type and number of instances. — shape: {InstanceType?: any, InstanceCount?: any, DedicatedMasterEnabled?: any, ZoneAwarenessEnabled?: any, ZoneAwarenessConfig?: any, DedicatedMasterType?: any, DedicatedMasterCount?: any, WarmEnabled?: any, WarmType?: any, WarmCount?: any, ColdStorageOptions?: any}
  --ebs-options: record # Options to enable, disable, and specify the properties of EBS storage volumes. For more information, see Configuring EBS-based Storage (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-ebs). — shape: {EBSEnabled?: any, VolumeType?: any, VolumeSize?: any, Iops?: any, Throughput?: any}
  --snapshot-options: record # Specifies the time, in UTC format, when the service takes a daily automated snapshot of the specified Elasticsearch domain. Default value is 0 hours. — shape: {AutomatedSnapshotStartHour?: any}
  --vpc-options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --cognito-options: record # Options to specify the Cognito user and identity pools for Kibana authentication. For more information, see Amazon Cognito Authentication for Kibana (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-cognito-auth.html). — shape: {Enabled?: any, UserPoolId?: any, IdentityPoolId?: any, RoleArn?: any}
  --advanced-options: record # Exposes select native Elasticsearch configuration values from elasticsearch.yml. Currently, the following advanced options are available: Option to allow references to indices in an HTTP request body. Must be false when configuring access to individual sub-resources. By default, the value is true. See Configuration Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options) for more information. Option to specify the percentage of heap space that is allocated to field data. By default, this setting is unbounded. For more information, see Configuring Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options).
  --access-policies: string # Access policy rules for an Elasticsearch domain service endpoints. For more information, see Configuring Access Policies (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-access-policies) in the Amazon Elasticsearch Service Developer Guide. The maximum size of a policy document is 100 KB.
  --log-publishing-options: record # Map of LogType and LogPublishingOption, each containing options to publish a given type of Elasticsearch log.
  --domain-endpoint-options: record # Options to configure endpoint for the Elasticsearch domain. — shape: {EnforceHTTPS?: any, TLSSecurityPolicy?: any, CustomEndpointEnabled?: any, CustomEndpoint?: any, CustomEndpointCertificateArn?: any}
  --advanced-security-options: record # Specifies the advanced security configuration: whether advanced security is enabled, whether the internal database option is enabled, master username and password (if internal database is enabled), and master user ARN (if IAM is enabled). — shape: {Enabled?: any, InternalUserDatabaseEnabled?: any, MasterUserOptions?: any, SAMLOptions?: any, AnonymousAuthEnabled?: any}
  --node-to-node-encryption-options: record # Specifies the node-to-node encryption options. — shape: {Enabled?: any}
  --encryption-at-rest-options: record # Specifies the Encryption At Rest Options. — shape: {Enabled?: any, KmsKeyId?: any}
  --auto-tune-options: record # Specifies the Auto-Tune options: the Auto-Tune desired state for the domain, rollback state when disabling Auto-Tune options and list of maintenance schedules. — shape: {DesiredState?: any, RollbackOnDisable?: any, MaintenanceSchedules?: any}
  --body-dry-run: oneof<nothing, bool> # This flag, when set to True, specifies whether the UpdateElasticsearchDomain request should return the results of validation checks without actually applying the change. This flag, when set to True, specifies the deployment mechanism through which the update shall be applied on the domain. This will not actually perform the Update.
]: any -> record<DomainConfig: record<ElasticsearchVersion: record<Options: record, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: record, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>, DryRunResults: record<DeploymentType: record, Message: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/config") $auth.query)
  let req_body = {"ElasticsearchClusterConfig": $elasticsearch_cluster_config, "EBSOptions": $ebs_options, "SnapshotOptions": $snapshot_options, "VPCOptions": $vpc_options, "CognitoOptions": $cognito_options, "AdvancedOptions": $advanced_options, "AccessPolicies": $access_policies, "LogPublishingOptions": $log_publishing_options, "DomainEndpointOptions": $domain_endpoint_options, "AdvancedSecurityOptions": $advanced_security_options, "NodeToNodeEncryptionOptions": $node_to_node_encryption_options, "EncryptionAtRestOptions": $encryption_at_rest_options, "AutoTuneOptions": $auto_tune_options, "DryRun": $body_dry_run} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
#
# POST /2015-01-01/es/domain-info
# operationId: DescribeElasticsearchDomains
export def "2015-01-01-es-domain-info get-elasticsearch" [
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
  domain_names: list<string> # A list of Elasticsearch domain names.
]: any -> record<DomainStatusList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/domain-info" $auth.query)
  let req_body = {"DomainNames": $domain_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the DomainName to know what Limits are supported for modifying.
#
# GET /2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}
# operationId: DescribeElasticsearchInstanceTypeLimits
export def "2015-01-01-es-instance-type-limits get-elasticsearch" [
  elasticsearch_version: string
  instance_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # DomainName represents the name of the Domain that we are trying to modify. This should be present only if we are querying for Elasticsearch Limits for existing domain.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<LimitsByRole: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($elasticsearch_version | is-empty) { error make --unspanned { msg: "path parameter 'ElasticsearchVersion' must be non-empty" } }
  if ($instance_type | is-empty) { error make --unspanned { msg: "path parameter 'InstanceType' must be non-empty" } }
  let qp = [(serialize-qp "domainName" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({elasticsearch_version: (encode-path-segment $elasticsearch_version), instance_type: (encode-path-segment $instance_type)} | format pattern "/2015-01-01/es/instanceTypeLimits/{elasticsearch_version}/{instance_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"domainName": $domain_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all the inbound cross-cluster search connections for a destination domain.
#
# POST /2015-01-01/es/ccs/inboundConnection/search
# operationId: DescribeInboundCrossClusterSearchConnections
# --Filters item shape: {Name?: any, Values?: any}
export def "2015-01-01-es-ccs-inbound-connection-search get-cross" [
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
  --filters: list # A list of filters used to match properties for inbound cross-cluster search connection. Available Filter names for this operation are: cross-cluster-search-connection-id source-domain-info.domain-name source-domain-info.owner-id source-domain-info.region destination-domain-info.domain-name — item shape: {Name?: any, Values?: any}
  --max-results-body: int # Set this value to limit the number of results returned. (body field)
  --next-token-body: string # Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. (body field)
]: any -> record<CrossClusterSearchConnections: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/ccs/inboundConnection/search" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Lists all the outbound cross-cluster search connections for a source domain.
#
# POST /2015-01-01/es/ccs/outboundConnection/search
# operationId: DescribeOutboundCrossClusterSearchConnections
# --Filters item shape: {Name?: any, Values?: any}
export def "2015-01-01-es-ccs-outbound-connection-search get-cross" [
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
  --filters: list # A list of filters used to match properties for outbound cross-cluster search connection. Available Filter names for this operation are: cross-cluster-search-connection-id destination-domain-info.domain-name destination-domain-info.owner-id destination-domain-info.region source-domain-info.domain-name — item shape: {Name?: any, Values?: any}
  --max-results-body: int # Set this value to limit the number of results returned. (body field)
  --next-token-body: string # Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. (body field)
]: any -> record<CrossClusterSearchConnections: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/ccs/outboundConnection/search" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Describes all packages available to Amazon ES. Includes options for filtering, limiting the number of results, and pagination.
#
# POST /2015-01-01/packages/describe
# operationId: DescribePackages
# --Filters item shape: {Name?: any, Value?: any}
export def "2015-01-01-packages-describe get" [
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
  --filters: list # A list of DescribePackagesFilter to filter the packages included in a DescribePackages response. — item shape: {Name?: any, Value?: any}
  --max-results-body: int # Set this value to limit the number of results returned. (body field)
  --next-token-body: string # Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. (body field)
]: any -> record<PackageDetailsList: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/packages/describe" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Lists available reserved Elasticsearch instance offerings.
#
# GET /2015-01-01/es/reservedInstanceOfferings
# operationId: DescribeReservedElasticsearchInstanceOfferings
export def "2015-01-01-es-reserved-instance-offerings get-elasticsearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offering-id: string # The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  --max-results: int # Set this value to limit the number of results returned. If not specified, defaults to 100.
  --next-token: string # NextToken should be sent in case if earlier API call produced result containing NextToken. It is used for pagination.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, ReservedElasticsearchInstanceOfferings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offeringId" $offering_id "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/reservedInstanceOfferings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offeringId": $offering_id, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about reserved Elasticsearch instances for this account.
#
# GET /2015-01-01/es/reservedInstances
# operationId: DescribeReservedElasticsearchInstances
export def "2015-01-01-es-reserved-instances get-elasticsearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation-id: string # The reserved instance identifier filter value. Use this parameter to show only the reservation that matches the specified reserved Elasticsearch instance ID.
  --max-results: int # Set this value to limit the number of results returned. If not specified, defaults to 100.
  --next-token: string # NextToken should be sent in case if earlier API call produced result containing NextToken. It is used for pagination.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, ReservedElasticsearchInstances: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reservationId" $reservation_id "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/reservedInstances" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reservationId": $reservation_id, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Describes one or more Amazon OpenSearch Service-managed VPC endpoints.
#
# POST /2015-01-01/es/vpcEndpoints/describe
# operationId: DescribeVpcEndpoints
export def "2015-01-01-es-vpc-endpoints-describe get" [
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
  vpc_endpoint_ids: list<string> # The unique identifiers of the endpoints to get information about.
]: any -> record<VpcEndpoints: record, VpcEndpointErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints/describe" $auth.query)
  let req_body = {"VpcEndpointIds": $vpc_endpoint_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Dissociates a package from the Amazon ES domain.
#
# POST /2015-01-01/packages/dissociate/{PackageID}/{DomainName}
# operationId: DissociatePackage
export def "2015-01-01-packages-dissociate create" [
  package_id: string
  domain_name: string
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
]: nothing -> record<DomainPackageDetails: record<PackageID: record, PackageName: record, PackageType: record, LastUpdated: record, DomainName: record, DomainPackageStatus: record, PackageVersion: string, ReferencePath: record, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id), domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/packages/dissociate/{package_id}/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a DomainName to get all upgrade compatible Elasticsearch versions for that specific domain.
#
# GET /2015-01-01/es/compatibleVersions
# operationId: GetCompatibleElasticsearchVersions
export def "2015-01-01-es-compatible-versions get-elasticsearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CompatibleElasticsearchVersions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainName" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/compatibleVersions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"domainName": $domain_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of versions of the package, along with their creation time and commit message.
#
# GET /2015-01-01/packages/{PackageID}/history
# operationId: GetPackageVersionHistory
export def "2015-01-01-packages-history get-version" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Limits results to a maximum number of versions.
  --next-token: string # Used for pagination. Only necessary if a previous API call includes a non-null NextToken value. If provided, returns results for the next page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<PackageID: string, PackageVersionHistoryList: record, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/2015-01-01/packages/{package_id}/history") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves the complete history of the last 10 upgrades that were performed on the domain.
#
# GET /2015-01-01/es/upgradeDomain/{DomainName}/history
# operationId: GetUpgradeHistory
export def "2015-01-01-es-upgrade-domain-history get" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UpgradeHistories: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/upgradeDomain/{domain_name}/history") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
#
# GET /2015-01-01/es/upgradeDomain/{DomainName}/status
# operationId: GetUpgradeStatus
export def "2015-01-01-es-upgrade-domain-status get" [
  domain_name: string
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
]: nothing -> record<UpgradeStep: record, StepStatus: record, UpgradeName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/upgradeDomain/{domain_name}/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the name of all Elasticsearch domains owned by the current user's account.
#
# GET /2015-01-01/domain
# operationId: ListDomainNames
export def "2015-01-01-domain list-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine-type: string@engine-type-completer # Optional parameter to filter the output by domain engine type. Acceptable values are 'Elasticsearch' and 'OpenSearch'.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DomainNames: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "engineType" $engine_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/domain" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"engineType": $engine_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all Amazon ES domains associated with the package.
#
# GET /2015-01-01/packages/{PackageID}/domains
# operationId: ListDomainsForPackage
export def "2015-01-01-packages-domains list" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Limits results to a maximum number of domains.
  --next-token: string # Used for pagination. Only necessary if a previous API call includes a non-null NextToken value. If provided, returns results for the next page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DomainPackageDetailsList: record, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/2015-01-01/packages/{package_id}/domains") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all Elasticsearch instance types that are supported for given ElasticsearchVersion
#
# GET /2015-01-01/es/instanceTypes/{ElasticsearchVersion}
# operationId: ListElasticsearchInstanceTypes
export def "2015-01-01-es-instance-types list-elasticsearch" [
  elasticsearch_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # DomainName represents the name of the Domain that we are trying to modify. This should be present only if we are querying for list of available Elasticsearch instance types when modifying existing domain.
  --max-results: int # Set this value to limit the number of results returned. Value provided must be greater than 30 else it wont be honored.
  --next-token: string # NextToken should be sent in case if earlier API call produced result containing NextToken. It is used for pagination.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ElasticsearchInstanceTypes: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($elasticsearch_version | is-empty) { error make --unspanned { msg: "path parameter 'ElasticsearchVersion' must be non-empty" } }
  let qp = [(serialize-qp "domainName" $domain_name "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({elasticsearch_version: (encode-path-segment $elasticsearch_version)} | format pattern "/2015-01-01/es/instanceTypes/{elasticsearch_version}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"domainName": $domain_name, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all supported Elasticsearch versions
#
# GET /2015-01-01/es/versions
# operationId: ListElasticsearchVersions
export def "2015-01-01-es-versions list-elasticsearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Set this value to limit the number of results returned. Value provided must be greater than 10 else it wont be honored.
  --next-token: string
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ElasticsearchVersions: list<string>, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/versions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all packages associated with the Amazon ES domain.
#
# GET /2015-01-01/domain/{DomainName}/packages
# operationId: ListPackagesForDomain
export def "2015-01-01-domain-packages list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Limits results to a maximum number of packages.
  --next-token: string # Used for pagination. Only necessary if a previous API call includes a non-null NextToken value. If provided, returns results for the next page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DomainPackageDetailsList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/domain/{domain_name}/packages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all tags for the given Elasticsearch domain.
#
# GET /2015-01-01/tags/
# operationId: ListTags
export def "2015-01-01-tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --arn: string # Specify the ARN for the Elasticsearch domain to which the tags are attached that you want to view.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TagList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "arn" $arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/tags/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"arn": $arn} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves information about each principal that is allowed to access a given Amazon OpenSearch Service domain through the use of an interface VPC endpoint.
#
# GET /2015-01-01/es/domain/{DomainName}/listVpcEndpointAccess
# operationId: ListVpcEndpointAccess
export def "2015-01-01-es-domain-list-vpc-endpoint-access list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Provides an identifier to allow retrieval of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AuthorizedPrincipalList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/listVpcEndpointAccess") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves all Amazon OpenSearch Service-managed VPC endpoints associated with a particular domain.
#
# GET /2015-01-01/es/domain/{DomainName}/vpcEndpoints
# operationId: ListVpcEndpointsForDomain
export def "2015-01-01-es-domain-vpc-endpoints list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Provides an identifier to allow retrieval of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<VpcEndpointSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/vpcEndpoints") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows you to purchase reserved Elasticsearch instances.
#
# POST /2015-01-01/es/purchaseReservedInstanceOffering
# operationId: PurchaseReservedElasticsearchInstanceOffering
export def "2015-01-01-es-purchase-reserved-instance-offering create-elasticsearch" [
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
  reserved_elasticsearch_instance_offering_id: string # The ID of the reserved Elasticsearch instance offering to purchase.
  reservation_name: string # A customer-specified identifier to track this reservation.
  --instance-count: int # Specifies the number of EC2 instances in the Elasticsearch domain.
]: any -> record<ReservedElasticsearchInstanceId: record, ReservationName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/purchaseReservedInstanceOffering" $auth.query)
  let req_body = {"ReservedElasticsearchInstanceOfferingId": $reserved_elasticsearch_instance_offering_id, "ReservationName": $reservation_name, "InstanceCount": $instance_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Allows the destination domain owner to reject an inbound cross-cluster search connection request.
#
# PUT /2015-01-01/es/ccs/inboundConnection/{ConnectionId}/reject
# operationId: RejectInboundCrossClusterSearchConnection
export def "2015-01-01-es-ccs-inbound-connection-reject list-cross" [
  connection_id: string
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
]: nothing -> record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: record, ConnectionStatus: record<StatusCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'ConnectionId' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/2015-01-01/es/ccs/inboundConnection/{connection_id}/reject") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Removes the specified set of tags from the specified Elasticsearch domain.
#
# POST /2015-01-01/tags-removal
# operationId: RemoveTags
export def "2015-01-01-tags-removal delete" [
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
  arn: string # The Amazon Resource Name (ARN) of the Elasticsearch domain. See Identifiers for IAM Entities (http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html) in Using AWS Identity and Access Management for more information.
  tag_keys: list<string> # Specifies the TagKey list which you want to remove from the Elasticsearch domain.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/tags-removal" $auth.query)
  let req_body = {"ARN": $arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Revokes access to an Amazon OpenSearch Service domain that was provided through an interface VPC endpoint.
#
# POST /2015-01-01/es/domain/{DomainName}/revokeVpcEndpointAccess
# operationId: RevokeVpcEndpointAccess
export def "2015-01-01-es-domain-revoke-vpc-endpoint-access delete" [
  domain_name: string
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
  account: string # The account ID to revoke access from.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/revokeVpcEndpointAccess") $auth.query)
  let req_body = {"Account": $account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Schedules a service software update for an Amazon ES domain.
#
# POST /2015-01-01/es/serviceSoftwareUpdate/start
# operationId: StartElasticsearchServiceSoftwareUpdate
export def "2015-01-01-es-service-software-update-start start-elasticsearch" [
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
  domain_name: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
]: any -> record<ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/serviceSoftwareUpdate/start" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Updates a package for use with Amazon ES domains.
#
# POST /2015-01-01/packages/update
# operationId: UpdatePackage
# --PackageSource shape: {S3BucketName?: any, S3Key?: any}
export def "2015-01-01-packages-update update" [
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
  package_id: string # Unique identifier for the package.
  package_source: record # The S3 location for importing the package specified as S3BucketName and S3Key — shape: {S3BucketName?: any, S3Key?: any}
  --package-description: string # New description of the package.
  --commit-message: string # An info message for the new version which will be shown as part of GetPackageVersionHistoryResponse.
]: any -> record<PackageDetails: record<PackageID: record, PackageName: record, PackageType: record, PackageDescription: record, PackageStatus: record, CreatedAt: record, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/packages/update" $auth.query)
  let req_body = {"PackageID": $package_id, "PackageSource": $package_source, "PackageDescription": $package_description, "CommitMessage": $commit_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Modifies an Amazon OpenSearch Service-managed interface VPC endpoint.
#
# POST /2015-01-01/es/vpcEndpoints/update
# operationId: UpdateVpcEndpoint
# --VpcOptions shape: {SubnetIds?: any, SecurityGroupIds?: any}
export def "2015-01-01-es-vpc-endpoints-update update" [
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
  vpc_endpoint_id: string # Unique identifier of the VPC endpoint to be updated.
  vpc_options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: any, SecurityGroupIds?: any}
]: any -> record<VpcEndpoint: record<VpcEndpointId: record, VpcEndpointOwner: record, DomainArn: record, VpcOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, Status: record, Endpoint: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints/update" $auth.query)
  let req_body = {"VpcEndpointId": $vpc_endpoint_id, "VpcOptions": $vpc_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
#
# POST /2015-01-01/es/upgradeDomain
# operationId: UpgradeElasticsearchDomain
export def "2015-01-01-es-upgrade-domain create-elasticsearch" [
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
  domain_name: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  target_version: string # The version of Elasticsearch that you intend to upgrade the domain to.
  --perform-check-only: oneof<nothing, bool> # This flag, when set to True, indicates that an Upgrade Eligibility Check needs to be performed. This will not actually perform the Upgrade.
]: any -> record<DomainName: string, TargetVersion: record, PerformCheckOnly: record, ChangeProgressDetails: record<ChangeId: record, Message: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/upgradeDomain" $auth.query)
  let req_body = {"DomainName": $domain_name, "TargetVersion": $target_version, "PerformCheckOnly": $perform_check_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
