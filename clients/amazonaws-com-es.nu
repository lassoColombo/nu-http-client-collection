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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
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
def instance-type-completer [] { ["c4.2xlarge.elasticsearch" "c4.4xlarge.elasticsearch" "c4.8xlarge.elasticsearch" "c4.large.elasticsearch" "c4.xlarge.elasticsearch" "c5.18xlarge.elasticsearch" "c5.2xlarge.elasticsearch" "c5.4xlarge.elasticsearch" "c5.9xlarge.elasticsearch" "c5.large.elasticsearch" "c5.xlarge.elasticsearch" "d2.2xlarge.elasticsearch" "d2.4xlarge.elasticsearch" "d2.8xlarge.elasticsearch" "d2.xlarge.elasticsearch" "i2.2xlarge.elasticsearch" "i2.xlarge.elasticsearch" "i3.16xlarge.elasticsearch" "i3.2xlarge.elasticsearch" "i3.4xlarge.elasticsearch" "i3.8xlarge.elasticsearch" "i3.large.elasticsearch" "i3.xlarge.elasticsearch" "m3.2xlarge.elasticsearch" "m3.large.elasticsearch" "m3.medium.elasticsearch" "m3.xlarge.elasticsearch" "m4.10xlarge.elasticsearch" "m4.2xlarge.elasticsearch" "m4.4xlarge.elasticsearch" "m4.large.elasticsearch" "m4.xlarge.elasticsearch" "m5.12xlarge.elasticsearch" "m5.2xlarge.elasticsearch" "m5.4xlarge.elasticsearch" "m5.large.elasticsearch" "m5.xlarge.elasticsearch" "r3.2xlarge.elasticsearch" "r3.4xlarge.elasticsearch" "r3.8xlarge.elasticsearch" "r3.large.elasticsearch" "r3.xlarge.elasticsearch" "r4.16xlarge.elasticsearch" "r4.2xlarge.elasticsearch" "r4.4xlarge.elasticsearch" "r4.8xlarge.elasticsearch" "r4.large.elasticsearch" "r4.xlarge.elasticsearch" "r5.12xlarge.elasticsearch" "r5.2xlarge.elasticsearch" "r5.4xlarge.elasticsearch" "r5.large.elasticsearch" "r5.xlarge.elasticsearch" "t2.medium.elasticsearch" "t2.micro.elasticsearch" "t2.small.elasticsearch" "ultrawarm1.large.elasticsearch" "ultrawarm1.medium.elasticsearch"] }
def engine-type-completer [] { ["Elasticsearch" "OpenSearch"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-inbound-cross-cluster-search-connection" "add-tags" "associate-package" "authorize-vpc-endpoint-access" "cancel-elasticsearch-service-software-update" "create-elasticsearch-domain" "create-outbound-cross-cluster-search-connection" "create-package" "create-vpc-endpoint" "list-vpc-endpoints" "delete-elasticsearch-domain" "describe-elasticsearch-domain" "delete-elasticsearch-service-role" "delete-inbound-cross-cluster-search-connection" "delete-outbound-cross-cluster-search-connection" "delete-package" "delete-vpc-endpoint" "describe-domain-auto-tunes" "describe-domain-change-progress" "describe-elasticsearch-domain-config" "update-elasticsearch-domain-config" "describe-elasticsearch-domains" "describe-elasticsearch-instance-type-limits" "describe-inbound-cross-cluster-search-connections" "describe-outbound-cross-cluster-search-connections" "describe-packages" "describe-reserved-elasticsearch-instance-offerings" "describe-reserved-elasticsearch-instances" "describe-vpc-endpoints" "dissociate-package" "get-compatible-elasticsearch-versions" "get-package-version-history" "get-upgrade-history" "get-upgrade-status" "list-domain-names" "list-domains-for-package" "list-elasticsearch-instance-types" "list-elasticsearch-versions" "list-packages-for-domain" "list-tags" "list-vpc-endpoint-access" "list-vpc-endpoints-for-domain" "purchase-reserved-elasticsearch-instance-offering" "reject-inbound-cross-cluster-search-connection" "remove-tags" "revoke-vpc-endpoint-access" "start-elasticsearch-service-software-update" "update-package" "update-vpc-endpoint" "upgrade-elasticsearch-domain" "commands"] | sort) } | get name | first)
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

# Allows the destination domain owner to accept an inbound cross-cluster search connection request.
#
# PUT /2015-01-01/es/ccs/inboundConnection/{ConnectionId}/accept
# operationId: AcceptInboundCrossClusterSearchConnection
export def "accept-inbound-cross-cluster-search-connection" [
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
]: nothing -> oneof<record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionStatus: record<StatusCode: string, Message: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'ConnectionId' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/2015-01-01/es/ccs/inboundConnection/{connection_id}/accept") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "add-tags" [
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
  tag_list: list # A list of Tag — item shape: {Key: string, Value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/tags" $auth.query)
  let req_body = {"ARN": $arn, "TagList": $tag_list} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Associates a package with an Amazon ES domain.
#
# POST /2015-01-01/packages/associate/{PackageID}/{DomainName}
# operationId: AssociatePackage
export def "associate-package" [
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
]: nothing -> oneof<record<DomainPackageDetails: record<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id), domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/packages/associate/{package_id}/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "authorize-vpc-endpoint-access" [
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
]: any -> oneof<record<AuthorizedPrincipal: record<PrincipalType: string, Principal: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/authorizeVpcEndpointAccess") $auth.query)
  let req_body = {"Account": $account} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the AutomatedUpdateDate and when the UpdateStatus is in the PENDING_UPDATE state.
#
# POST /2015-01-01/es/serviceSoftwareUpdate/cancel
# operationId: CancelElasticsearchServiceSoftwareUpdate
export def "cancel-elasticsearch-service-software-update" [
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
]: any -> oneof<record<ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/serviceSoftwareUpdate/cancel" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Creates a new Elasticsearch domain. For more information, see Creating Elasticsearch Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains) in the Amazon Elasticsearch Service Developer Guide.
#
# POST /2015-01-01/es/domain
# operationId: CreateElasticsearchDomain
export def "create-elasticsearch-domain" [
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
  --elasticsearch-cluster-config: record # Specifies the configuration for the domain cluster, such as the type and number of instances. — shape: {InstanceType?: "m3.medium.elasticsearch"|"m3.large.elasticsearch"|"m3.xlarge.elasticsearch"|"m3.2xlarge.elasticsearch"|"m4.large.elasticsearch"|"m4.xlarge.elasticsearch"|"m4.2xlarge.elasticsearch"|"m4.4xlarge.elasticsearch"|"m4.10xlarge.elasticsearch"|"m5.large.elasticsearch"|"m5.xlarge.elasticsearch"|"m5.2xlarge.elasticsearch"|"m5.4xlarge.elasticsearch"|"m5.12xlarge.elasticsearch"|"r5.large.elasticsearch"|"r5.xlarge.elasticsearch"|"r5.2xlarge.elasticsearch"|"r5.4xlarge.elasticsearch"|"r5.12xlarge.elasticsearch"|"c5.large.elasticsearch"|"c5.xlarge.elasticsearch"|"c5.2xlarge.elasticsearch"|"c5.4xlarge.elasticsearch"|"c5.9xlarge.elasticsearch"|"c5.18xlarge.elasticsearch"|"ultrawarm1.medium.elasticsearch"|"ultrawarm1.large.elasticsearch"|"t2.micro.elasticsearch"|"t2.small.elasticsearch"|"t2.medium.elasticsearch"|"r3.large.elasticsearch"|"r3.xlarge.elasticsearch"|"r3.2xlarge.elasticsearch"|"r3.4xlarge.elasticsearch"|"r3.8xlarge.elasticsearch"|"i2.xlarge.elasticsearch"|"i2.2xlarge.elasticsearch"|"d2.xlarge.elasticsearch"|"d2.2xlarge.elasticsearch"|"d2.4xlarge.elasticsearch"|"d2.8xlarge.elasticsearch"|"c4.large.elasticsearch"|"c4.xlarge.elasticsearch"|"c4.2xlarge.elasticsearch"|"c4.4xlarge.elasticsearch"|"c4.8xlarge.elasticsearch"|"r4.large.elasticsearch"|"r4.xlarge.elasticsearch"|"r4.2xlarge.elasticsearch"|"r4.4xlarge.elasticsearch"|"r4.8xlarge.elasticsearch"|"r4.16xlarge.elasticsearch"|"i3.large.elasticsearch"|"i3.xlarge.elasticsearch"|"i3.2xlarge.elasticsearch"|"i3.4xlarge.elasticsearch"|"i3.8xlarge.elasticsearch"|"i3.16xlarge.elasticsearch", ... (10 more fields)}
  --ebs-options: record # Options to enable, disable, and specify the properties of EBS storage volumes. For more information, see Configuring EBS-based Storage (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-ebs). — shape: {EBSEnabled?: bool, VolumeType?: "standard"|"gp2"|"io1"|"gp3", VolumeSize?: int, Iops?: int, Throughput?: int}
  --access-policies: string # Access policy rules for an Elasticsearch domain service endpoints. For more information, see Configuring Access Policies (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-access-policies) in the Amazon Elasticsearch Service Developer Guide. The maximum size of a policy document is 100 KB.
  --snapshot-options: record # Specifies the time, in UTC format, when the service takes a daily automated snapshot of the specified Elasticsearch domain. Default value is 0 hours. — shape: {AutomatedSnapshotStartHour?: int}
  --vpc-options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --cognito-options: record # Options to specify the Cognito user and identity pools for Kibana authentication. For more information, see Amazon Cognito Authentication for Kibana (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-cognito-auth.html). — shape: {Enabled?: bool, UserPoolId?: string, IdentityPoolId?: string, RoleArn?: string}
  --encryption-at-rest-options: record # Specifies the Encryption At Rest Options. — shape: {Enabled?: bool, KmsKeyId?: string}
  --node-to-node-encryption-options: record # Specifies the node-to-node encryption options. — shape: {Enabled?: bool}
  --advanced-options: record # Exposes select native Elasticsearch configuration values from elasticsearch.yml. Currently, the following advanced options are available: Option to allow references to indices in an HTTP request body. Must be false when configuring access to individual sub-resources. By default, the value is true. See Configuration Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options) for more information. Option to specify the percentage of heap space that is allocated to field data. By default, this setting is unbounded. For more information, see Configuring Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options).
  --log-publishing-options: record # Map of LogType and LogPublishingOption, each containing options to publish a given type of Elasticsearch log.
  --domain-endpoint-options: record # Options to configure endpoint for the Elasticsearch domain. — shape: {EnforceHTTPS?: bool, TLSSecurityPolicy?: "Policy-Min-TLS-1-0-2019-07"|"Policy-Min-TLS-1-2-2019-07", CustomEndpointEnabled?: bool, CustomEndpoint?: string, CustomEndpointCertificateArn?: string}
  --advanced-security-options: record # Specifies the advanced security configuration: whether advanced security is enabled, whether the internal database option is enabled, master username and password (if internal database is enabled), and master user ARN (if IAM is enabled). — shape: {Enabled?: bool, InternalUserDatabaseEnabled?: bool, MasterUserOptions?: record, SAMLOptions?: record, AnonymousAuthEnabled?: bool}
  --auto-tune-options: record # Specifies the Auto-Tune options: the Auto-Tune desired state for the domain and list of maintenance schedules. — shape: {DesiredState?: "ENABLED"|"DISABLED", MaintenanceSchedules?: list}
  --tag-list: list # A list of Tag — item shape: {Key: string, Value: string}
]: any -> oneof<record<DomainStatus: record<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: string, InstanceCount: int, DedicatedMasterEnabled: bool, ZoneAwarenessEnabled: bool, ZoneAwarenessConfig: record, DedicatedMasterType: string, DedicatedMasterCount: int, WarmEnabled: bool, WarmType: string, WarmCount: int, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: bool, VolumeType: string, VolumeSize: int, Iops: int, Throughput: int>, AccessPolicies: string, SnapshotOptions: record<AutomatedSnapshotStartHour: int>, VPCOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, CognitoOptions: record<Enabled: bool, UserPoolId: string, IdentityPoolId: string, RoleArn: string>, EncryptionAtRestOptions: record<Enabled: bool, KmsKeyId: string>, NodeToNodeEncryptionOptions: record<Enabled: bool>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>, DomainEndpointOptions: record<EnforceHTTPS: bool, TLSSecurityPolicy: string, CustomEndpointEnabled: bool, CustomEndpoint: string, CustomEndpointCertificateArn: string>, AdvancedSecurityOptions: record<Enabled: bool, InternalUserDatabaseEnabled: bool, SAMLOptions: record, AnonymousAuthDisableDate: string, AnonymousAuthEnabled: bool>, AutoTuneOptions: record<State: string, ErrorMessage: string>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/domain" $auth.query)
  let req_body = {"DomainName": $domain_name, "ElasticsearchVersion": $elasticsearch_version, "ElasticsearchClusterConfig": $elasticsearch_cluster_config, "EBSOptions": $ebs_options, "AccessPolicies": $access_policies, "SnapshotOptions": $snapshot_options, "VPCOptions": $vpc_options, "CognitoOptions": $cognito_options, "EncryptionAtRestOptions": $encryption_at_rest_options, "NodeToNodeEncryptionOptions": $node_to_node_encryption_options, "AdvancedOptions": $advanced_options, "LogPublishingOptions": $log_publishing_options, "DomainEndpointOptions": $domain_endpoint_options, "AdvancedSecurityOptions": $advanced_security_options, "AutoTuneOptions": $auto_tune_options, "TagList": $tag_list} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Creates a new cross-cluster search connection from a source domain to a destination domain.
#
# POST /2015-01-01/es/ccs/outboundConnection
# operationId: CreateOutboundCrossClusterSearchConnection
export def "create-outbound-cross-cluster-search-connection" [
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
]: any -> oneof<record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, ConnectionAlias: string, ConnectionStatus: record<StatusCode: string, Message: string>, CrossClusterSearchConnectionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/ccs/outboundConnection" $auth.query)
  let req_body = {"SourceDomainInfo": $source_domain_info, "DestinationDomainInfo": $destination_domain_info, "ConnectionAlias": $connection_alias} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Create a package for use with Amazon ES domains.
#
# POST /2015-01-01/packages
# operationId: CreatePackage
export def "create-package" [
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
  package_source: record # The S3 location for importing the package specified as S3BucketName and S3Key — shape: {S3BucketName?: string, S3Key?: string}
]: any -> oneof<record<PackageDetails: record<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/packages" $auth.query)
  let req_body = {"PackageName": $package_name, "PackageType": $package_type, "PackageDescription": $package_description, "PackageSource": $package_source} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Creates an Amazon OpenSearch Service-managed VPC endpoint.
#
# POST /2015-01-01/es/vpcEndpoints
# operationId: CreateVpcEndpoint
export def "create-vpc-endpoint" [
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
  vpc_options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --client-token: string # Unique, case-sensitive identifier to ensure idempotency of the request.
]: any -> oneof<record<VpcEndpoint: record<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, VpcOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, Status: string, Endpoint: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints" $auth.query)
  let req_body = {"DomainArn": $domain_arn, "VpcOptions": $vpc_options, "ClientToken": $client_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Retrieves all Amazon OpenSearch Service-managed VPC endpoints in the current account and Region.
#
# GET /2015-01-01/es/vpcEndpoints
# operationId: ListVpcEndpoints
export def "list-vpc-endpoints" [
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
]: nothing -> oneof<record<VpcEndpointSummaryList: table<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, Status: string>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-elasticsearch-domain" [
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
]: nothing -> oneof<record<DomainStatus: record<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: string, InstanceCount: int, DedicatedMasterEnabled: bool, ZoneAwarenessEnabled: bool, ZoneAwarenessConfig: record, DedicatedMasterType: string, DedicatedMasterCount: int, WarmEnabled: bool, WarmType: string, WarmCount: int, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: bool, VolumeType: string, VolumeSize: int, Iops: int, Throughput: int>, AccessPolicies: string, SnapshotOptions: record<AutomatedSnapshotStartHour: int>, VPCOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, CognitoOptions: record<Enabled: bool, UserPoolId: string, IdentityPoolId: string, RoleArn: string>, EncryptionAtRestOptions: record<Enabled: bool, KmsKeyId: string>, NodeToNodeEncryptionOptions: record<Enabled: bool>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>, DomainEndpointOptions: record<EnforceHTTPS: bool, TLSSecurityPolicy: string, CustomEndpointEnabled: bool, CustomEndpoint: string, CustomEndpointCertificateArn: string>, AdvancedSecurityOptions: record<Enabled: bool, InternalUserDatabaseEnabled: bool, SAMLOptions: record, AnonymousAuthDisableDate: string, AnonymousAuthEnabled: bool>, AutoTuneOptions: record<State: string, ErrorMessage: string>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-elasticsearch-domain" [
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
]: nothing -> oneof<record<DomainStatus: record<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: string, InstanceCount: int, DedicatedMasterEnabled: bool, ZoneAwarenessEnabled: bool, ZoneAwarenessConfig: record, DedicatedMasterType: string, DedicatedMasterCount: int, WarmEnabled: bool, WarmType: string, WarmCount: int, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: bool, VolumeType: string, VolumeSize: int, Iops: int, Throughput: int>, AccessPolicies: string, SnapshotOptions: record<AutomatedSnapshotStartHour: int>, VPCOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, CognitoOptions: record<Enabled: bool, UserPoolId: string, IdentityPoolId: string, RoleArn: string>, EncryptionAtRestOptions: record<Enabled: bool, KmsKeyId: string>, NodeToNodeEncryptionOptions: record<Enabled: bool>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>, DomainEndpointOptions: record<EnforceHTTPS: bool, TLSSecurityPolicy: string, CustomEndpointEnabled: bool, CustomEndpoint: string, CustomEndpointCertificateArn: string>, AdvancedSecurityOptions: record<Enabled: bool, InternalUserDatabaseEnabled: bool, SAMLOptions: record, AnonymousAuthDisableDate: string, AnonymousAuthEnabled: bool>, AutoTuneOptions: record<State: string, ErrorMessage: string>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-elasticsearch-service-role" [
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
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-inbound-cross-cluster-search-connection" [
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
]: nothing -> oneof<record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionStatus: record<StatusCode: string, Message: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'ConnectionId' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/2015-01-01/es/ccs/inboundConnection/{connection_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-outbound-cross-cluster-search-connection" [
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
]: nothing -> oneof<record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionAlias: string, ConnectionStatus: record<StatusCode: string, Message: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'ConnectionId' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/2015-01-01/es/ccs/outboundConnection/{connection_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-package" [
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
]: nothing -> oneof<record<PackageDetails: record<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/2015-01-01/packages/{package_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-vpc-endpoint" [
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
]: nothing -> oneof<record<VpcEndpointSummary: record<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, Status: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_endpoint_id | is-empty) { error make --unspanned { msg: "path parameter 'VpcEndpointId' must be non-empty" } }
  let full_url = (build-url $base ({vpc_endpoint_id: (encode-path-segment $vpc_endpoint_id)} | format pattern "/2015-01-01/es/vpcEndpoints/{vpc_endpoint_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-domain-auto-tunes" [
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
]: nothing -> oneof<record<AutoTunes: table<AutoTuneType: string, AutoTuneDetails: record>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/autoTunes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-domain-change-progress" [
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
]: nothing -> oneof<record<ChangeProgressStatus: record<ChangeId: string, StartTime: string, Status: string, PendingProperties: list<string>, CompletedProperties: list<string>, TotalNumberOfStages: int, ChangeProgressStages: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "changeid" $changeid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/progress") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-elasticsearch-domain-config" [
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
]: nothing -> oneof<record<DomainConfig: record<ElasticsearchVersion: record<Options: string, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: string, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/config") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-elasticsearch-domain-config" [
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
  --elasticsearch-cluster-config: record # Specifies the configuration for the domain cluster, such as the type and number of instances. — shape: {InstanceType?: "m3.medium.elasticsearch"|"m3.large.elasticsearch"|"m3.xlarge.elasticsearch"|"m3.2xlarge.elasticsearch"|"m4.large.elasticsearch"|"m4.xlarge.elasticsearch"|"m4.2xlarge.elasticsearch"|"m4.4xlarge.elasticsearch"|"m4.10xlarge.elasticsearch"|"m5.large.elasticsearch"|"m5.xlarge.elasticsearch"|"m5.2xlarge.elasticsearch"|"m5.4xlarge.elasticsearch"|"m5.12xlarge.elasticsearch"|"r5.large.elasticsearch"|"r5.xlarge.elasticsearch"|"r5.2xlarge.elasticsearch"|"r5.4xlarge.elasticsearch"|"r5.12xlarge.elasticsearch"|"c5.large.elasticsearch"|"c5.xlarge.elasticsearch"|"c5.2xlarge.elasticsearch"|"c5.4xlarge.elasticsearch"|"c5.9xlarge.elasticsearch"|"c5.18xlarge.elasticsearch"|"ultrawarm1.medium.elasticsearch"|"ultrawarm1.large.elasticsearch"|"t2.micro.elasticsearch"|"t2.small.elasticsearch"|"t2.medium.elasticsearch"|"r3.large.elasticsearch"|"r3.xlarge.elasticsearch"|"r3.2xlarge.elasticsearch"|"r3.4xlarge.elasticsearch"|"r3.8xlarge.elasticsearch"|"i2.xlarge.elasticsearch"|"i2.2xlarge.elasticsearch"|"d2.xlarge.elasticsearch"|"d2.2xlarge.elasticsearch"|"d2.4xlarge.elasticsearch"|"d2.8xlarge.elasticsearch"|"c4.large.elasticsearch"|"c4.xlarge.elasticsearch"|"c4.2xlarge.elasticsearch"|"c4.4xlarge.elasticsearch"|"c4.8xlarge.elasticsearch"|"r4.large.elasticsearch"|"r4.xlarge.elasticsearch"|"r4.2xlarge.elasticsearch"|"r4.4xlarge.elasticsearch"|"r4.8xlarge.elasticsearch"|"r4.16xlarge.elasticsearch"|"i3.large.elasticsearch"|"i3.xlarge.elasticsearch"|"i3.2xlarge.elasticsearch"|"i3.4xlarge.elasticsearch"|"i3.8xlarge.elasticsearch"|"i3.16xlarge.elasticsearch", ... (10 more fields)}
  --ebs-options: record # Options to enable, disable, and specify the properties of EBS storage volumes. For more information, see Configuring EBS-based Storage (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-ebs). — shape: {EBSEnabled?: bool, VolumeType?: "standard"|"gp2"|"io1"|"gp3", VolumeSize?: int, Iops?: int, Throughput?: int}
  --snapshot-options: record # Specifies the time, in UTC format, when the service takes a daily automated snapshot of the specified Elasticsearch domain. Default value is 0 hours. — shape: {AutomatedSnapshotStartHour?: int}
  --vpc-options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --cognito-options: record # Options to specify the Cognito user and identity pools for Kibana authentication. For more information, see Amazon Cognito Authentication for Kibana (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-cognito-auth.html). — shape: {Enabled?: bool, UserPoolId?: string, IdentityPoolId?: string, RoleArn?: string}
  --advanced-options: record # Exposes select native Elasticsearch configuration values from elasticsearch.yml. Currently, the following advanced options are available: Option to allow references to indices in an HTTP request body. Must be false when configuring access to individual sub-resources. By default, the value is true. See Configuration Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options) for more information. Option to specify the percentage of heap space that is allocated to field data. By default, this setting is unbounded. For more information, see Configuring Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options).
  --access-policies: string # Access policy rules for an Elasticsearch domain service endpoints. For more information, see Configuring Access Policies (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-access-policies) in the Amazon Elasticsearch Service Developer Guide. The maximum size of a policy document is 100 KB.
  --log-publishing-options: record # Map of LogType and LogPublishingOption, each containing options to publish a given type of Elasticsearch log.
  --domain-endpoint-options: record # Options to configure endpoint for the Elasticsearch domain. — shape: {EnforceHTTPS?: bool, TLSSecurityPolicy?: "Policy-Min-TLS-1-0-2019-07"|"Policy-Min-TLS-1-2-2019-07", CustomEndpointEnabled?: bool, CustomEndpoint?: string, CustomEndpointCertificateArn?: string}
  --advanced-security-options: record # Specifies the advanced security configuration: whether advanced security is enabled, whether the internal database option is enabled, master username and password (if internal database is enabled), and master user ARN (if IAM is enabled). — shape: {Enabled?: bool, InternalUserDatabaseEnabled?: bool, MasterUserOptions?: record, SAMLOptions?: record, AnonymousAuthEnabled?: bool}
  --node-to-node-encryption-options: record # Specifies the node-to-node encryption options. — shape: {Enabled?: bool}
  --encryption-at-rest-options: record # Specifies the Encryption At Rest Options. — shape: {Enabled?: bool, KmsKeyId?: string}
  --auto-tune-options: record # Specifies the Auto-Tune options: the Auto-Tune desired state for the domain, rollback state when disabling Auto-Tune options and list of maintenance schedules. — shape: {DesiredState?: "ENABLED"|"DISABLED", RollbackOnDisable?: "NO_ROLLBACK"|"DEFAULT_ROLLBACK", MaintenanceSchedules?: list}
  --body-dry-run: oneof<nothing, bool> # This flag, when set to True, specifies whether the UpdateElasticsearchDomain request should return the results of validation checks without actually applying the change. This flag, when set to True, specifies the deployment mechanism through which the update shall be applied on the domain. This will not actually perform the Update. (spec name: DryRun)
]: any -> oneof<record<DomainConfig: record<ElasticsearchVersion: record<Options: string, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: string, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: string, Message: string>>, DryRunResults: record<DeploymentType: string, Message: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/config") $auth.query)
  let req_body = {"ElasticsearchClusterConfig": $elasticsearch_cluster_config, "EBSOptions": $ebs_options, "SnapshotOptions": $snapshot_options, "VPCOptions": $vpc_options, "CognitoOptions": $cognito_options, "AdvancedOptions": $advanced_options, "AccessPolicies": $access_policies, "LogPublishingOptions": $log_publishing_options, "DomainEndpointOptions": $domain_endpoint_options, "AdvancedSecurityOptions": $advanced_security_options, "NodeToNodeEncryptionOptions": $node_to_node_encryption_options, "EncryptionAtRestOptions": $encryption_at_rest_options, "AutoTuneOptions": $auto_tune_options, "DryRun": $body_dry_run} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
#
# POST /2015-01-01/es/domain-info
# operationId: DescribeElasticsearchDomains
export def "describe-elasticsearch-domains" [
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
]: any -> oneof<record<DomainStatusList: table<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record, EBSOptions: record, AccessPolicies: string, SnapshotOptions: record, VPCOptions: record, CognitoOptions: record, EncryptionAtRestOptions: record, NodeToNodeEncryptionOptions: record, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record, DomainEndpointOptions: record, AdvancedSecurityOptions: record, AutoTuneOptions: record, ChangeProgressDetails: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/domain-info" $auth.query)
  let req_body = {"DomainNames": $domain_names} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the DomainName to know what Limits are supported for modifying.
#
# GET /2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}
# operationId: DescribeElasticsearchInstanceTypeLimits
export def "describe-elasticsearch-instance-type-limits" [
  elasticsearch_version: string
  instance_type: string@instance-type-completer
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
]: nothing -> oneof<record<LimitsByRole: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($elasticsearch_version | is-empty) { error make --unspanned { msg: "path parameter 'ElasticsearchVersion' must be non-empty" } }
  if ($instance_type | is-empty) { error make --unspanned { msg: "path parameter 'InstanceType' must be non-empty" } }
  let qp = [(serialize-qp "domainName" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({elasticsearch_version: (encode-path-segment $elasticsearch_version), instance_type: (encode-path-segment $instance_type)} | format pattern "/2015-01-01/es/instanceTypeLimits/{elasticsearch_version}/{instance_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-inbound-cross-cluster-search-connections" [
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
  --filters: list # A list of filters used to match properties for inbound cross-cluster search connection. Available Filter names for this operation are: cross-cluster-search-connection-id source-domain-info.domain-name source-domain-info.owner-id source-domain-info.region destination-domain-info.domain-name — item shape: {Name?: string, Values?: list<string>}
  --body-max-results: int # Set this value to limit the number of results returned. (spec name: MaxResults)
  --body-next-token: string # Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. (spec name: NextToken)
]: any -> oneof<record<CrossClusterSearchConnections: table<SourceDomainInfo: record, DestinationDomainInfo: record, CrossClusterSearchConnectionId: string, ConnectionStatus: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/ccs/inboundConnection/search" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Lists all the outbound cross-cluster search connections for a source domain.
#
# POST /2015-01-01/es/ccs/outboundConnection/search
# operationId: DescribeOutboundCrossClusterSearchConnections
export def "describe-outbound-cross-cluster-search-connections" [
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
  --filters: list # A list of filters used to match properties for outbound cross-cluster search connection. Available Filter names for this operation are: cross-cluster-search-connection-id destination-domain-info.domain-name destination-domain-info.owner-id destination-domain-info.region source-domain-info.domain-name — item shape: {Name?: string, Values?: list<string>}
  --body-max-results: int # Set this value to limit the number of results returned. (spec name: MaxResults)
  --body-next-token: string # Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. (spec name: NextToken)
]: any -> oneof<record<CrossClusterSearchConnections: table<SourceDomainInfo: record, DestinationDomainInfo: record, CrossClusterSearchConnectionId: string, ConnectionAlias: string, ConnectionStatus: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/ccs/outboundConnection/search" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Describes all packages available to Amazon ES. Includes options for filtering, limiting the number of results, and pagination.
#
# POST /2015-01-01/packages/describe
# operationId: DescribePackages
export def "describe-packages" [
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
  --filters: list # A list of DescribePackagesFilter to filter the packages included in a DescribePackages response. — item shape: {Name?: "PackageID"|"PackageName"|"PackageStatus", Value?: list<string>}
  --body-max-results: int # Set this value to limit the number of results returned. (spec name: MaxResults)
  --body-next-token: string # Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. (spec name: NextToken)
]: any -> oneof<record<PackageDetailsList: table<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/packages/describe" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Lists available reserved Elasticsearch instance offerings.
#
# GET /2015-01-01/es/reservedInstanceOfferings
# operationId: DescribeReservedElasticsearchInstanceOfferings
export def "describe-reserved-elasticsearch-instance-offerings" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<NextToken: string, ReservedElasticsearchInstanceOfferings: table<ReservedElasticsearchInstanceOfferingId: string, ElasticsearchInstanceType: string, Duration: int, FixedPrice: float, UsagePrice: float, CurrencyCode: string, PaymentOption: string, RecurringCharges: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offeringId" $offering_id "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/reservedInstanceOfferings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offeringId": $offering_id, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
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
export def "describe-reserved-elasticsearch-instances" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<NextToken: string, ReservedElasticsearchInstances: table<ReservationName: string, ReservedElasticsearchInstanceId: string, ReservedElasticsearchInstanceOfferingId: string, ElasticsearchInstanceType: string, StartTime: string, Duration: int, FixedPrice: float, UsagePrice: float, CurrencyCode: string, ElasticsearchInstanceCount: int, State: string, PaymentOption: string, RecurringCharges: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reservationId" $reservation_id "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/reservedInstances" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reservationId": $reservation_id, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
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
export def "describe-vpc-endpoints" [
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
]: any -> oneof<record<VpcEndpoints: table<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, VpcOptions: record, Status: string, Endpoint: string>, VpcEndpointErrors: table<VpcEndpointId: string, ErrorCode: string, ErrorMessage: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints/describe" $auth.query)
  let req_body = {"VpcEndpointIds": $vpc_endpoint_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Dissociates a package from the Amazon ES domain.
#
# POST /2015-01-01/packages/dissociate/{PackageID}/{DomainName}
# operationId: DissociatePackage
export def "dissociate-package" [
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
]: nothing -> oneof<record<DomainPackageDetails: record<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id), domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/packages/dissociate/{package_id}/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "get-compatible-elasticsearch-versions" [
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
]: nothing -> oneof<record<CompatibleElasticsearchVersions: table<SourceVersion: string, TargetVersions: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainName" $domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/compatibleVersions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "get-package-version-history" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<PackageID: string, PackageVersionHistoryList: table<PackageVersion: string, CommitMessage: string, CreatedAt: string>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/2015-01-01/packages/{package_id}/history") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
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
export def "get-upgrade-history" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<UpgradeHistories: table<UpgradeName: string, StartTimestamp: string, UpgradeStatus: string, StepsList: list>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/upgradeDomain/{domain_name}/history") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
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
export def "get-upgrade-status" [
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
]: nothing -> oneof<record<UpgradeStep: string, StepStatus: string, UpgradeName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/upgradeDomain/{domain_name}/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-domain-names" [
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
]: nothing -> oneof<record<DomainNames: table<DomainName: string, EngineType: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "engineType" $engine_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/domain" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-domains-for-package" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DomainPackageDetailsList: table<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($package_id | is-empty) { error make --unspanned { msg: "path parameter 'PackageID' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({package_id: (encode-path-segment $package_id)} | format pattern "/2015-01-01/packages/{package_id}/domains") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
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
export def "list-elasticsearch-instance-types" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<ElasticsearchInstanceTypes: list<string>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($elasticsearch_version | is-empty) { error make --unspanned { msg: "path parameter 'ElasticsearchVersion' must be non-empty" } }
  let qp = [(serialize-qp "domainName" $domain_name "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({elasticsearch_version: (encode-path-segment $elasticsearch_version)} | format pattern "/2015-01-01/es/instanceTypes/{elasticsearch_version}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"domainName": $domain_name, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
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
export def "list-elasticsearch-versions" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<ElasticsearchVersions: list<string>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/versions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
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
export def "list-packages-for-domain" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DomainPackageDetailsList: table<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/domain/{domain_name}/packages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
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
export def "list-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --arn: string # Specify the ARN for the Elasticsearch domain to which the tags are attached that you want to view. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<TagList: table<Key: string, Value: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($arn == null) { error make --unspanned { msg: "required query parameter 'arn' missing: pass --arn" } }
  let qp = [(serialize-qp "arn" $arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/tags/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-vpc-endpoint-access" [
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
]: nothing -> oneof<record<AuthorizedPrincipalList: table<PrincipalType: string, Principal: string>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/listVpcEndpointAccess") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-vpc-endpoints-for-domain" [
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
]: nothing -> oneof<record<VpcEndpointSummaryList: table<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, Status: string>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/vpcEndpoints") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "purchase-reserved-elasticsearch-instance-offering" [
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
]: any -> oneof<record<ReservedElasticsearchInstanceId: string, ReservationName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/purchaseReservedInstanceOffering" $auth.query)
  let req_body = {"ReservedElasticsearchInstanceOfferingId": $reserved_elasticsearch_instance_offering_id, "ReservationName": $reservation_name, "InstanceCount": $instance_count} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Allows the destination domain owner to reject an inbound cross-cluster search connection request.
#
# PUT /2015-01-01/es/ccs/inboundConnection/{ConnectionId}/reject
# operationId: RejectInboundCrossClusterSearchConnection
export def "reject-inbound-cross-cluster-search-connection" [
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
]: nothing -> oneof<record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionStatus: record<StatusCode: string, Message: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'ConnectionId' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/2015-01-01/es/ccs/inboundConnection/{connection_id}/reject") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "remove-tags" [
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
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Revokes access to an Amazon OpenSearch Service domain that was provided through an interface VPC endpoint.
#
# POST /2015-01-01/es/domain/{DomainName}/revokeVpcEndpointAccess
# operationId: RevokeVpcEndpointAccess
export def "revoke-vpc-endpoint-access" [
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
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'DomainName' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/2015-01-01/es/domain/{domain_name}/revokeVpcEndpointAccess") $auth.query)
  let req_body = {"Account": $account} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Schedules a service software update for an Amazon ES domain.
#
# POST /2015-01-01/es/serviceSoftwareUpdate/start
# operationId: StartElasticsearchServiceSoftwareUpdate
export def "start-elasticsearch-service-software-update" [
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
]: any -> oneof<record<ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/serviceSoftwareUpdate/start" $auth.query)
  let req_body = {"DomainName": $domain_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Updates a package for use with Amazon ES domains.
#
# POST /2015-01-01/packages/update
# operationId: UpdatePackage
export def "update-package" [
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
  package_source: record # The S3 location for importing the package specified as S3BucketName and S3Key — shape: {S3BucketName?: string, S3Key?: string}
  --package-description: string # New description of the package.
  --commit-message: string # An info message for the new version which will be shown as part of GetPackageVersionHistoryResponse.
]: any -> oneof<record<PackageDetails: record<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/packages/update" $auth.query)
  let req_body = {"PackageID": $package_id, "PackageSource": $package_source, "PackageDescription": $package_description, "CommitMessage": $commit_message} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Modifies an Amazon OpenSearch Service-managed interface VPC endpoint.
#
# POST /2015-01-01/es/vpcEndpoints/update
# operationId: UpdateVpcEndpoint
export def "update-vpc-endpoint" [
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
  vpc_options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
]: any -> oneof<record<VpcEndpoint: record<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, VpcOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, Status: string, Endpoint: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints/update" $auth.query)
  let req_body = {"VpcEndpointId": $vpc_endpoint_id, "VpcOptions": $vpc_options} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
#
# POST /2015-01-01/es/upgradeDomain
# operationId: UpgradeElasticsearchDomain
export def "upgrade-elasticsearch-domain" [
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
]: any -> oneof<record<DomainName: string, TargetVersion: string, PerformCheckOnly: bool, ChangeProgressDetails: record<ChangeId: string, Message: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/upgradeDomain" $auth.query)
  let req_body = {"DomainName": $domain_name, "TargetVersion": $target_version, "PerformCheckOnly": $perform_check_only} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
