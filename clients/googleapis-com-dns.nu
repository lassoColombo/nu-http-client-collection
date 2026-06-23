# Auto-generated client for Cloud DNS API vv2
# Source: https://api.apis.guru/v2/specs/googleapis.com/dns/v2/openapi.json
# Auth: --token flag or $env.CLOUD_DNS_API_TOKEN

const BASE_URL = "https://dns.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_DNS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://dns.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def visibility-completer [] { ["PRIVATE" "PUBLIC"] }
def sort-by-completer [] { ["CHANGE_SEQUENCE"] }
def status-completer [] { ["DONE" "PENDING"] }
def sort-by-completer-1 [] { ["ID" "START_TIME"] }
def behavior-completer [] { ["BEHAVIOR_UNSPECIFIED" "BYPASS_RESPONSE_POLICY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "dns-projects-locations get" } } | get name | first)
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

# Fetches the representation of an existing Project.
#
# GET /dns/v2/projects/{project}/locations/{location}
# operationId: dns.projects.get
export def "dns-projects-locations get" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> record<id: string, kind: string, number: string, quota: record<dnsKeysPerManagedZone: int, gkeClustersPerManagedZone: int, gkeClustersPerPolicy: int, gkeClustersPerResponsePolicy: int, itemsPerRoutingPolicy: int, kind: string, managedZones: int, managedZonesPerGkeCluster: int, managedZonesPerNetwork: int, networksPerManagedZone: int, networksPerPolicy: int, networksPerResponsePolicy: int, peeringZonesPerTargetNetwork: int, policies: int, resourceRecordsPerRrset: int, responsePolicies: int, responsePolicyRulesPerResponsePolicy: int, rrsetAdditionsPerChange: int, rrsetDeletionsPerChange: int, rrsetsPerManagedZone: int, targetNameServersPerManagedZone: int, targetNameServersPerPolicy: int, totalRrdataSizePerChange: int, whitelistedKeySpecs: list<record>>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/dns/v2/projects/{project}/locations/{location}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Enumerates ManagedZones that have been created but not yet deleted.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones
# operationId: dns.managedZones.list
export def "dns-projects-locations-managed-zones list" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --dns-name: string # Restricts the list to return only zones with this domain name.
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> record<header: record<operationId: string>, kind: string, managedZones: table<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dnsName" $dns_name "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "dnsName": $dns_name, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Creates a new ManagedZone.
#
# POST /dns/v2/projects/{project}/locations/{location}/managedZones
# operationId: dns.managedZones.create
# --cloudLoggingConfig shape: {enableLogging?: bool, kind?: string}
# --dnssecConfig shape: {defaultKeySpecs?: list, kind?: string, nonExistence?: "NSEC"|"NSEC3", state?: "OFF"|"ON"|"TRANSFER"}
# --forwardingConfig shape: {kind?: string, targetNameServers?: list}
# --peeringConfig shape: {kind?: string, targetNetwork?: record}
# --privateVisibilityConfig shape: {gkeClusters?: list, kind?: string, networks?: list}
# --reverseLookupConfig shape: {kind?: string}
# --serviceDirectoryConfig shape: {kind?: string, namespace?: record}
export def "dns-projects-locations-managed-zones create" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --cloud-logging-config: record # Cloud Logging configurations for publicly visible zones. — shape: {enableLogging?: bool, kind?: string}
  --creation-time: string # The time that this resource was created on the server. This is in RFC3339 text format. Output only.
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the managed zone's function.
  --dns-name: string # The DNS name of this managed zone, for instance "example.com.".
  --dnssec-config: record # shape: {defaultKeySpecs?: list, kind?: string, nonExistence?: "NSEC"|"NSEC3", state?: "OFF"|"ON"|"TRANSFER"}
  --forwarding-config: record # shape: {kind?: string, targetNameServers?: list}
  --id: string # Unique identifier for the resource; defined by the server (output only) (format: uint64)
  --kind: string # default: dns#managedZone
  --labels: record # User labels.
  --name: string # User assigned name for this resource. Must be unique within the project. The name must be 1-63 characters long, must begin with a letter, end with a letter or digit, and only contain lowercase letters, digits or dashes.
  --name-server-set: string # Optionally specifies the NameServerSet for this ManagedZone. A NameServerSet is a set of DNS name servers that all host the same ManagedZones. Most users leave this field unset. If you need to use this field, contact your account team.
  --name-servers: list<string> # Delegate your managed_zone to these virtual name servers; defined by the server (output only)
  --peering-config: record # shape: {kind?: string, targetNetwork?: record}
  --private-visibility-config: record # shape: {gkeClusters?: list, kind?: string, networks?: list}
  --reverse-lookup-config: record # shape: {kind?: string}
  --service-directory-config: record # Contains information about Service Directory-backed zones. — shape: {kind?: string, namespace?: record}
  --visibility: string@visibility-completer # The zone's visibility: public zones are exposed to the Internet, while private zones are visible only to Virtual Private Cloud resources.
]: any -> record<cloudLoggingConfig: record<enableLogging: bool, kind: string>, creationTime: string, description: string, dnsName: string, dnssecConfig: record<defaultKeySpecs: list<record>, kind: string, nonExistence: string, state: string>, forwardingConfig: record<kind: string, targetNameServers: list<record>>, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list<string>, peeringConfig: record<kind: string, targetNetwork: record<deactivateTime: string, kind: string, networkUrl: string>>, privateVisibilityConfig: record<gkeClusters: list<record>, kind: string, networks: list<record>>, reverseLookupConfig: record<kind: string>, serviceDirectoryConfig: record<kind: string, namespace: record<deletionTime: string, kind: string, namespaceUrl: string>>, visibility: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones") $qp)
  let req_body = {"cloudLoggingConfig": $cloud_logging_config, "creationTime": $creation_time, "description": $description, "dnsName": $dns_name, "dnssecConfig": $dnssec_config, "forwardingConfig": $forwarding_config, "id": $id, "kind": $kind, "labels": $labels, "name": $name, "nameServerSet": $name_server_set, "nameServers": $name_servers, "peeringConfig": $peering_config, "privateVisibilityConfig": $private_visibility_config, "reverseLookupConfig": $reverse_lookup_config, "serviceDirectoryConfig": $service_directory_config, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Deletes a previously created ManagedZone.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}
# operationId: dns.managedZones.delete
export def "dns-projects-locations-managed-zones delete" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Fetches the representation of an existing ManagedZone.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}
# operationId: dns.managedZones.get
export def "dns-projects-locations-managed-zones get" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> record<cloudLoggingConfig: record<enableLogging: bool, kind: string>, creationTime: string, description: string, dnsName: string, dnssecConfig: record<defaultKeySpecs: list<record>, kind: string, nonExistence: string, state: string>, forwardingConfig: record<kind: string, targetNameServers: list<record>>, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list<string>, peeringConfig: record<kind: string, targetNetwork: record<deactivateTime: string, kind: string, networkUrl: string>>, privateVisibilityConfig: record<gkeClusters: list<record>, kind: string, networks: list<record>>, reverseLookupConfig: record<kind: string>, serviceDirectoryConfig: record<kind: string, namespace: record<deletionTime: string, kind: string, namespaceUrl: string>>, visibility: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Applies a partial update to an existing ManagedZone.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}
# operationId: dns.managedZones.patch
# --cloudLoggingConfig shape: {enableLogging?: bool, kind?: string}
# --dnssecConfig shape: {defaultKeySpecs?: list, kind?: string, nonExistence?: "NSEC"|"NSEC3", state?: "OFF"|"ON"|"TRANSFER"}
# --forwardingConfig shape: {kind?: string, targetNameServers?: list}
# --peeringConfig shape: {kind?: string, targetNetwork?: record}
# --privateVisibilityConfig shape: {gkeClusters?: list, kind?: string, networks?: list}
# --reverseLookupConfig shape: {kind?: string}
# --serviceDirectoryConfig shape: {kind?: string, namespace?: record}
export def "dns-projects-locations-managed-zones update-by-project-location-managed-zone" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --cloud-logging-config: record # Cloud Logging configurations for publicly visible zones. — shape: {enableLogging?: bool, kind?: string}
  --creation-time: string # The time that this resource was created on the server. This is in RFC3339 text format. Output only.
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the managed zone's function.
  --dns-name: string # The DNS name of this managed zone, for instance "example.com.".
  --dnssec-config: record # shape: {defaultKeySpecs?: list, kind?: string, nonExistence?: "NSEC"|"NSEC3", state?: "OFF"|"ON"|"TRANSFER"}
  --forwarding-config: record # shape: {kind?: string, targetNameServers?: list}
  --id: string # Unique identifier for the resource; defined by the server (output only) (format: uint64)
  --kind: string # default: dns#managedZone
  --labels: record # User labels.
  --name: string # User assigned name for this resource. Must be unique within the project. The name must be 1-63 characters long, must begin with a letter, end with a letter or digit, and only contain lowercase letters, digits or dashes.
  --name-server-set: string # Optionally specifies the NameServerSet for this ManagedZone. A NameServerSet is a set of DNS name servers that all host the same ManagedZones. Most users leave this field unset. If you need to use this field, contact your account team.
  --name-servers: list<string> # Delegate your managed_zone to these virtual name servers; defined by the server (output only)
  --peering-config: record # shape: {kind?: string, targetNetwork?: record}
  --private-visibility-config: record # shape: {gkeClusters?: list, kind?: string, networks?: list}
  --reverse-lookup-config: record # shape: {kind?: string}
  --service-directory-config: record # Contains information about Service Directory-backed zones. — shape: {kind?: string, namespace?: record}
  --visibility: string@visibility-completer # The zone's visibility: public zones are exposed to the Internet, while private zones are visible only to Virtual Private Cloud resources.
]: any -> record<dnsKeyContext: record<newValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, oldValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>>, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record<newValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, oldValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}") $qp)
  let req_body = {"cloudLoggingConfig": $cloud_logging_config, "creationTime": $creation_time, "description": $description, "dnsName": $dns_name, "dnssecConfig": $dnssec_config, "forwardingConfig": $forwarding_config, "id": $id, "kind": $kind, "labels": $labels, "name": $name, "nameServerSet": $name_server_set, "nameServers": $name_servers, "peeringConfig": $peering_config, "privateVisibilityConfig": $private_visibility_config, "reverseLookupConfig": $reverse_lookup_config, "serviceDirectoryConfig": $service_directory_config, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Updates an existing ManagedZone.
#
# PUT /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}
# operationId: dns.managedZones.update
# --cloudLoggingConfig shape: {enableLogging?: bool, kind?: string}
# --dnssecConfig shape: {defaultKeySpecs?: list, kind?: string, nonExistence?: "NSEC"|"NSEC3", state?: "OFF"|"ON"|"TRANSFER"}
# --forwardingConfig shape: {kind?: string, targetNameServers?: list}
# --peeringConfig shape: {kind?: string, targetNetwork?: record}
# --privateVisibilityConfig shape: {gkeClusters?: list, kind?: string, networks?: list}
# --reverseLookupConfig shape: {kind?: string}
# --serviceDirectoryConfig shape: {kind?: string, namespace?: record}
export def "dns-projects-locations-managed-zones update-by-project-location-managed-zone-1" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --cloud-logging-config: record # Cloud Logging configurations for publicly visible zones. — shape: {enableLogging?: bool, kind?: string}
  --creation-time: string # The time that this resource was created on the server. This is in RFC3339 text format. Output only.
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the managed zone's function.
  --dns-name: string # The DNS name of this managed zone, for instance "example.com.".
  --dnssec-config: record # shape: {defaultKeySpecs?: list, kind?: string, nonExistence?: "NSEC"|"NSEC3", state?: "OFF"|"ON"|"TRANSFER"}
  --forwarding-config: record # shape: {kind?: string, targetNameServers?: list}
  --id: string # Unique identifier for the resource; defined by the server (output only) (format: uint64)
  --kind: string # default: dns#managedZone
  --labels: record # User labels.
  --name: string # User assigned name for this resource. Must be unique within the project. The name must be 1-63 characters long, must begin with a letter, end with a letter or digit, and only contain lowercase letters, digits or dashes.
  --name-server-set: string # Optionally specifies the NameServerSet for this ManagedZone. A NameServerSet is a set of DNS name servers that all host the same ManagedZones. Most users leave this field unset. If you need to use this field, contact your account team.
  --name-servers: list<string> # Delegate your managed_zone to these virtual name servers; defined by the server (output only)
  --peering-config: record # shape: {kind?: string, targetNetwork?: record}
  --private-visibility-config: record # shape: {gkeClusters?: list, kind?: string, networks?: list}
  --reverse-lookup-config: record # shape: {kind?: string}
  --service-directory-config: record # Contains information about Service Directory-backed zones. — shape: {kind?: string, namespace?: record}
  --visibility: string@visibility-completer # The zone's visibility: public zones are exposed to the Internet, while private zones are visible only to Virtual Private Cloud resources.
]: any -> record<dnsKeyContext: record<newValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, oldValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>>, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record<newValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, oldValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}") $qp)
  let req_body = {"cloudLoggingConfig": $cloud_logging_config, "creationTime": $creation_time, "description": $description, "dnsName": $dns_name, "dnssecConfig": $dnssec_config, "forwardingConfig": $forwarding_config, "id": $id, "kind": $kind, "labels": $labels, "name": $name, "nameServerSet": $name_server_set, "nameServers": $name_servers, "peeringConfig": $peering_config, "privateVisibilityConfig": $private_visibility_config, "reverseLookupConfig": $reverse_lookup_config, "serviceDirectoryConfig": $service_directory_config, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Enumerates Changes to a ResourceRecordSet collection.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/changes
# operationId: dns.changes.list
export def "dns-projects-locations-managed-zones-changes list" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
  --sort-by: string@sort-by-completer # Sorting criterion. The only supported value is change sequence.
  --sort-order: string # Sorting order direction: 'ascending' or 'descending'.
]: nothing -> record<changes: table<additions: list, deletions: list, id: string, isServing: bool, kind: string, startTime: string, status: string>, header: record<operationId: string>, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/changes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "pageToken": $page_token, "sortBy": $sort_by, "sortOrder": $sort_order} | compact), body: null}
}

# Atomically updates the ResourceRecordSet collection.
#
# POST /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/changes
# operationId: dns.changes.create
# --additions item shape: {kind?: string, name?: string, routingPolicy?: record, rrdatas?: list<string>, signatureRrdatas?: list<string>, ttl?: int, type?: string}
# --deletions item shape: {kind?: string, name?: string, routingPolicy?: record, rrdatas?: list<string>, signatureRrdatas?: list<string>, ttl?: int, type?: string}
export def "dns-projects-locations-managed-zones-changes create" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --additions: list # Which ResourceRecordSets to add? — item shape: {kind?: string, name?: string, routingPolicy?: record, rrdatas?: list<string>, signatureRrdatas?: list<string>, ttl?: int, type?: string}
  --deletions: list # Which ResourceRecordSets to remove? Must match existing data exactly. — item shape: {kind?: string, name?: string, routingPolicy?: record, rrdatas?: list<string>, signatureRrdatas?: list<string>, ttl?: int, type?: string}
  --id: string # Unique identifier for the resource; defined by the server (output only).
  --is-serving: oneof<nothing, bool> # If the DNS queries for the zone will be served.
  --kind: string # default: dns#change
  --start-time: string # The time that this operation was started by the server (output only). This is in RFC3339 text format.
  --status: string@status-completer # Status of the operation (output only). A status of "done" means that the request to update the authoritative servers has been sent, but the servers might not be updated yet.
]: any -> record<additions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, deletions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, id: string, isServing: bool, kind: string, startTime: string, status: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/changes") $qp)
  let req_body = {"additions": $additions, "deletions": $deletions, "id": $id, "isServing": $is_serving, "kind": $kind, "startTime": $start_time, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Fetches the representation of an existing Change.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/changes/{changeId}
# operationId: dns.changes.get
export def "dns-projects-locations-managed-zones-changes get" [
  project: string
  location: string
  managed_zone: string
  change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> record<additions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, deletions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, id: string, isServing: bool, kind: string, startTime: string, status: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  if ($change_id | is-empty) { error make --unspanned { msg: "path parameter 'changeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone), change_id: (encode-path-segment $change_id)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/changes/{change_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Enumerates DnsKeys to a ResourceRecordSet collection.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/dnsKeys
# operationId: dns.dnsKeys.list
export def "dns-projects-locations-managed-zones-dns-keys list" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --digest-type: string # An optional comma-separated list of digest types to compute and display for key signing keys. If omitted, the recommended digest type is computed and displayed.
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> record<dnsKeys: table<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, header: record<operationId: string>, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "digestType" $digest_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/dnsKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "digestType": $digest_type, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Fetches the representation of an existing DnsKey.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/dnsKeys/{dnsKeyId}
# operationId: dns.dnsKeys.get
export def "dns-projects-locations-managed-zones-dns-keys get" [
  project: string
  location: string
  managed_zone: string
  dns_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --digest-type: string # An optional comma-separated list of digest types to compute and display for key signing keys. If omitted, the recommended digest type is computed and displayed.
]: nothing -> record<algorithm: string, creationTime: string, description: string, digests: table<digest: string, type: string>, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  if ($dns_key_id | is-empty) { error make --unspanned { msg: "path parameter 'dnsKeyId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar") (serialize-qp "digestType" $digest_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone), dns_key_id: (encode-path-segment $dns_key_id)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/dnsKeys/{dns_key_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id, "digestType": $digest_type} | compact), body: null}
}

# Enumerates Operations for the given ManagedZone.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/operations
# operationId: dns.managedZoneOperations.list
export def "dns-projects-locations-managed-zones-operations list" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
  --sort-by: string@sort-by-completer-1 # Sorting criterion. The only supported values are START_TIME and ID.
]: nothing -> record<header: record<operationId: string>, kind: string, nextPageToken: string, operations: table<dnsKeyContext: record, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "sortBy" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "pageToken": $page_token, "sortBy": $sort_by} | compact), body: null}
}

# Fetches the representation of an existing Operation.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/operations/{operation}
# operationId: dns.managedZoneOperations.get
export def "dns-projects-locations-managed-zones-operations get" [
  project: string
  location: string
  managed_zone: string
  operation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> record<dnsKeyContext: record<newValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, oldValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>>, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record<newValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, oldValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  if ($operation | is-empty) { error make --unspanned { msg: "path parameter 'operation' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone), operation: (encode-path-segment $operation)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/operations/{operation}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Enumerates ResourceRecordSets that you have created but not yet deleted.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets
# operationId: dns.resourceRecordSets.list
export def "dns-projects-locations-managed-zones-rrsets list" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --name: string # Restricts the list to return only records with this fully qualified domain name.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
  --type: string # Restricts the list to return only records of this type. If present, the "name" parameter must also be present.
]: nothing -> record<header: record<operationId: string>, kind: string, nextPageToken: string, rrsets: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/rrsets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "name": $name, "pageToken": $page_token, "type": $type} | compact), body: null}
}

# Creates a new ResourceRecordSet.
#
# POST /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets
# operationId: dns.resourceRecordSets.create
# --routingPolicy shape: {geo?: record, kind?: string, primaryBackup?: record, wrr?: record}
export def "dns-projects-locations-managed-zones-rrsets create" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --kind: string # default: dns#resourceRecordSet
  --name: string # For example, www.example.com.
  --routing-policy: record # A RRSetRoutingPolicy represents ResourceRecordSet data that is returned dynamically with the response varying based on configured properties such as geolocation or by weighted random selection. — shape: {geo?: record, kind?: string, primaryBackup?: record, wrr?: record}
  --rrdatas: list<string> # As defined in RFC 1035 (section 5) and RFC 1034 (section 3.6.1) -- see examples.
  --signature-rrdatas: list<string> # As defined in RFC 4034 (section 3.2).
  --ttl: int # Number of seconds that this ResourceRecordSet can be cached by resolvers. (format: int32)
  --type: string # The identifier of a supported record type. See the list of Supported DNS record types.
]: any -> record<kind: string, name: string, routingPolicy: record<geo: record<enableFencing: bool, items: list, kind: string>, kind: string, primaryBackup: record<backupGeoTargets: record, kind: string, primaryTargets: record, trickleTraffic: float>, wrr: record<items: list, kind: string>>, rrdatas: list<string>, signatureRrdatas: list<string>, ttl: int, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/rrsets") $qp)
  let req_body = {"kind": $kind, "name": $name, "routingPolicy": $routing_policy, "rrdatas": $rrdatas, "signatureRrdatas": $signature_rrdatas, "ttl": $ttl, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Deletes a previously created ResourceRecordSet.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets/{name}/{type}
# operationId: dns.resourceRecordSets.delete
export def "dns-projects-locations-managed-zones-rrsets delete" [
  project: string
  location: string
  managed_zone: string
  name: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone), name: (encode-path-segment $name), type: (encode-path-segment $type)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/rrsets/{name}/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Fetches the representation of an existing ResourceRecordSet.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets/{name}/{type}
# operationId: dns.resourceRecordSets.get
export def "dns-projects-locations-managed-zones-rrsets get" [
  project: string
  location: string
  managed_zone: string
  name: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> record<kind: string, name: string, routingPolicy: record<geo: record<enableFencing: bool, items: list, kind: string>, kind: string, primaryBackup: record<backupGeoTargets: record, kind: string, primaryTargets: record, trickleTraffic: float>, wrr: record<items: list, kind: string>>, rrdatas: list<string>, signatureRrdatas: list<string>, ttl: int, type: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone), name: (encode-path-segment $name), type: (encode-path-segment $type)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/rrsets/{name}/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Applies a partial update to an existing ResourceRecordSet.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets/{name}/{type}
# operationId: dns.resourceRecordSets.patch
# --routingPolicy shape: {geo?: record, kind?: string, primaryBackup?: record, wrr?: record}
export def "dns-projects-locations-managed-zones-rrsets update" [
  project: string
  location: string
  managed_zone: string
  name: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --kind: string # default: dns#resourceRecordSet
  --body-name: string # For example, www.example.com.
  --routing-policy: record # A RRSetRoutingPolicy represents ResourceRecordSet data that is returned dynamically with the response varying based on configured properties such as geolocation or by weighted random selection. — shape: {geo?: record, kind?: string, primaryBackup?: record, wrr?: record}
  --rrdatas: list<string> # As defined in RFC 1035 (section 5) and RFC 1034 (section 3.6.1) -- see examples.
  --signature-rrdatas: list<string> # As defined in RFC 4034 (section 3.2).
  --ttl: int # Number of seconds that this ResourceRecordSet can be cached by resolvers. (format: int32)
  --body-type: string # The identifier of a supported record type. See the list of Supported DNS record types.
]: any -> record<kind: string, name: string, routingPolicy: record<geo: record<enableFencing: bool, items: list, kind: string>, kind: string, primaryBackup: record<backupGeoTargets: record, kind: string, primaryTargets: record, trickleTraffic: float>, wrr: record<items: list, kind: string>>, rrdatas: list<string>, signatureRrdatas: list<string>, ttl: int, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($managed_zone | is-empty) { error make --unspanned { msg: "path parameter 'managedZone' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), managed_zone: (encode-path-segment $managed_zone), name: (encode-path-segment $name), type: (encode-path-segment $type)} | format pattern "/dns/v2/projects/{project}/locations/{location}/managedZones/{managed_zone}/rrsets/{name}/{type}") $qp)
  let req_body = {"kind": $kind, "name": $body_name, "routingPolicy": $routing_policy, "rrdatas": $rrdatas, "signatureRrdatas": $signature_rrdatas, "ttl": $ttl, "type": $body_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Enumerates all Policies associated with a project.
#
# GET /dns/v2/projects/{project}/locations/{location}/policies
# operationId: dns.policies.list
export def "dns-projects-locations-policies list" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> record<header: record<operationId: string>, kind: string, nextPageToken: string, policies: table<alternativeNameServerConfig: record, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: list>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/dns/v2/projects/{project}/locations/{location}/policies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Creates a new Policy.
#
# POST /dns/v2/projects/{project}/locations/{location}/policies
# operationId: dns.policies.create
# --alternativeNameServerConfig shape: {kind?: string, targetNameServers?: list}
# --networks item shape: {kind?: string, networkUrl?: string}
export def "dns-projects-locations-policies create" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --alternative-name-server-config: record # shape: {kind?: string, targetNameServers?: list}
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the policy's function.
  --enable-inbound-forwarding: oneof<nothing, bool> # Allows networks bound to this policy to receive DNS queries sent by VMs or applications over VPN connections. When enabled, a virtual IP address is allocated from each of the subnetworks that are bound to this policy.
  --enable-logging: oneof<nothing, bool> # Controls whether logging is enabled for the networks bound to this policy. Defaults to no logging if not set.
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: uint64)
  --kind: string # default: dns#policy
  --name: string # User-assigned name for this policy.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
]: any -> record<alternativeNameServerConfig: record<kind: string, targetNameServers: list<record>>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: table<kind: string, networkUrl: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/dns/v2/projects/{project}/locations/{location}/policies") $qp)
  let req_body = {"alternativeNameServerConfig": $alternative_name_server_config, "description": $description, "enableInboundForwarding": $enable_inbound_forwarding, "enableLogging": $enable_logging, "id": $id, "kind": $kind, "name": $name, "networks": $networks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Deletes a previously created Policy. Fails if the policy is still being referenced by a network.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/policies/{policy}
# operationId: dns.policies.delete
export def "dns-projects-locations-policies delete" [
  project: string
  location: string
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($policy | is-empty) { error make --unspanned { msg: "path parameter 'policy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), policy: (encode-path-segment $policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/policies/{policy}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Fetches the representation of an existing Policy.
#
# GET /dns/v2/projects/{project}/locations/{location}/policies/{policy}
# operationId: dns.policies.get
export def "dns-projects-locations-policies get" [
  project: string
  location: string
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> record<alternativeNameServerConfig: record<kind: string, targetNameServers: list<record>>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: table<kind: string, networkUrl: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($policy | is-empty) { error make --unspanned { msg: "path parameter 'policy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), policy: (encode-path-segment $policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/policies/{policy}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Applies a partial update to an existing Policy.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/policies/{policy}
# operationId: dns.policies.patch
# --alternativeNameServerConfig shape: {kind?: string, targetNameServers?: list}
# --networks item shape: {kind?: string, networkUrl?: string}
export def "dns-projects-locations-policies update-by-project-location-policy" [
  project: string
  location: string
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --alternative-name-server-config: record # shape: {kind?: string, targetNameServers?: list}
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the policy's function.
  --enable-inbound-forwarding: oneof<nothing, bool> # Allows networks bound to this policy to receive DNS queries sent by VMs or applications over VPN connections. When enabled, a virtual IP address is allocated from each of the subnetworks that are bound to this policy.
  --enable-logging: oneof<nothing, bool> # Controls whether logging is enabled for the networks bound to this policy. Defaults to no logging if not set.
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: uint64)
  --kind: string # default: dns#policy
  --name: string # User-assigned name for this policy.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
]: any -> record<header: record<operationId: string>, policy: record<alternativeNameServerConfig: record<kind: string, targetNameServers: list>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: list<record>>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($policy | is-empty) { error make --unspanned { msg: "path parameter 'policy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), policy: (encode-path-segment $policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/policies/{policy}") $qp)
  let req_body = {"alternativeNameServerConfig": $alternative_name_server_config, "description": $description, "enableInboundForwarding": $enable_inbound_forwarding, "enableLogging": $enable_logging, "id": $id, "kind": $kind, "name": $name, "networks": $networks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Updates an existing Policy.
#
# PUT /dns/v2/projects/{project}/locations/{location}/policies/{policy}
# operationId: dns.policies.update
# --alternativeNameServerConfig shape: {kind?: string, targetNameServers?: list}
# --networks item shape: {kind?: string, networkUrl?: string}
export def "dns-projects-locations-policies update-by-project-location-policy-1" [
  project: string
  location: string
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --alternative-name-server-config: record # shape: {kind?: string, targetNameServers?: list}
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the policy's function.
  --enable-inbound-forwarding: oneof<nothing, bool> # Allows networks bound to this policy to receive DNS queries sent by VMs or applications over VPN connections. When enabled, a virtual IP address is allocated from each of the subnetworks that are bound to this policy.
  --enable-logging: oneof<nothing, bool> # Controls whether logging is enabled for the networks bound to this policy. Defaults to no logging if not set.
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: uint64)
  --kind: string # default: dns#policy
  --name: string # User-assigned name for this policy.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
]: any -> record<header: record<operationId: string>, policy: record<alternativeNameServerConfig: record<kind: string, targetNameServers: list>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: list<record>>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($policy | is-empty) { error make --unspanned { msg: "path parameter 'policy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), policy: (encode-path-segment $policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/policies/{policy}") $qp)
  let req_body = {"alternativeNameServerConfig": $alternative_name_server_config, "description": $description, "enableInboundForwarding": $enable_inbound_forwarding, "enableLogging": $enable_logging, "id": $id, "kind": $kind, "name": $name, "networks": $networks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Enumerates all Response Policies associated with a project.
#
# GET /dns/v2/projects/{project}/locations/{location}/responsePolicies
# operationId: dns.responsePolicies.list
export def "dns-projects-locations-response-policies list" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> record<header: record<operationId: string>, nextPageToken: string, responsePolicies: table<description: string, gkeClusters: list, id: string, kind: string, labels: record, networks: list, responsePolicyName: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Creates a new Response Policy
#
# POST /dns/v2/projects/{project}/locations/{location}/responsePolicies
# operationId: dns.responsePolicies.create
# --gkeClusters item shape: {gkeClusterName?: string, kind?: string}
# --networks item shape: {kind?: string, networkUrl?: string}
export def "dns-projects-locations-response-policies create" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --description: string # User-provided description for this Response Policy.
  --gke-clusters: list # The list of Google Kubernetes Engine clusters to which this response policy is applied. — item shape: {gkeClusterName?: string, kind?: string}
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: int64)
  --kind: string # default: dns#responsePolicy
  --labels: record # User labels.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
  --response-policy-name: string # User assigned name for this Response Policy.
]: any -> record<description: string, gkeClusters: table<gkeClusterName: string, kind: string>, id: string, kind: string, labels: record, networks: table<kind: string, networkUrl: string>, responsePolicyName: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies") $qp)
  let req_body = {"description": $description, "gkeClusters": $gke_clusters, "id": $id, "kind": $kind, "labels": $labels, "networks": $networks, "responsePolicyName": $response_policy_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Deletes a previously created Response Policy. Fails if the response policy is non-empty or still being referenced by a network.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}
# operationId: dns.responsePolicies.delete
export def "dns-projects-locations-response-policies delete" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Fetches the representation of an existing Response Policy.
#
# GET /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}
# operationId: dns.responsePolicies.get
export def "dns-projects-locations-response-policies get" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> record<description: string, gkeClusters: table<gkeClusterName: string, kind: string>, id: string, kind: string, labels: record, networks: table<kind: string, networkUrl: string>, responsePolicyName: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Applies a partial update to an existing Response Policy.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}
# operationId: dns.responsePolicies.patch
# --gkeClusters item shape: {gkeClusterName?: string, kind?: string}
# --networks item shape: {kind?: string, networkUrl?: string}
export def "dns-projects-locations-response-policies update-by-project-location-response-policy" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --description: string # User-provided description for this Response Policy.
  --gke-clusters: list # The list of Google Kubernetes Engine clusters to which this response policy is applied. — item shape: {gkeClusterName?: string, kind?: string}
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: int64)
  --kind: string # default: dns#responsePolicy
  --labels: record # User labels.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
  --response-policy-name: string # User assigned name for this Response Policy.
]: any -> record<header: record<operationId: string>, responsePolicy: record<description: string, gkeClusters: list<record>, id: string, kind: string, labels: record, networks: list<record>, responsePolicyName: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}") $qp)
  let req_body = {"description": $description, "gkeClusters": $gke_clusters, "id": $id, "kind": $kind, "labels": $labels, "networks": $networks, "responsePolicyName": $response_policy_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Updates an existing Response Policy.
#
# PUT /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}
# operationId: dns.responsePolicies.update
# --gkeClusters item shape: {gkeClusterName?: string, kind?: string}
# --networks item shape: {kind?: string, networkUrl?: string}
export def "dns-projects-locations-response-policies update-by-project-location-response-policy-1" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --description: string # User-provided description for this Response Policy.
  --gke-clusters: list # The list of Google Kubernetes Engine clusters to which this response policy is applied. — item shape: {gkeClusterName?: string, kind?: string}
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: int64)
  --kind: string # default: dns#responsePolicy
  --labels: record # User labels.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
  --response-policy-name: string # User assigned name for this Response Policy.
]: any -> record<header: record<operationId: string>, responsePolicy: record<description: string, gkeClusters: list<record>, id: string, kind: string, labels: record, networks: list<record>, responsePolicyName: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}") $qp)
  let req_body = {"description": $description, "gkeClusters": $gke_clusters, "id": $id, "kind": $kind, "labels": $labels, "networks": $networks, "responsePolicyName": $response_policy_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Enumerates all Response Policy Rules associated with a project.
#
# GET /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules
# operationId: dns.responsePolicyRules.list
export def "dns-projects-locations-response-policies-rules list" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> record<header: record<operationId: string>, nextPageToken: string, responsePolicyRules: table<behavior: string, dnsName: string, kind: string, localData: record, ruleName: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}/rules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Creates a new Response Policy Rule.
#
# POST /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules
# operationId: dns.responsePolicyRules.create
# --localData shape: {localDatas?: list}
export def "dns-projects-locations-response-policies-rules create" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --behavior: string@behavior-completer # Answer this query with a behavior rather than DNS data.
  --dns-name: string # The DNS name (wildcard or exact) to apply this rule to. Must be unique within the Response Policy Rule.
  --kind: string # default: dns#responsePolicyRule
  --local-data: record # shape: {localDatas?: list}
  --rule-name: string # An identifier for this rule. Must be unique with the ResponsePolicy.
]: any -> record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list<record>>, ruleName: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}/rules") $qp)
  let req_body = {"behavior": $behavior, "dnsName": $dns_name, "kind": $kind, "localData": $local_data, "ruleName": $rule_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Deletes a previously created Response Policy Rule.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}
# operationId: dns.responsePolicyRules.delete
export def "dns-projects-locations-response-policies-rules delete" [
  project: string
  location: string
  response_policy: string
  response_policy_rule: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  if ($response_policy_rule | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicyRule' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy), response_policy_rule: (encode-path-segment $response_policy_rule)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}/rules/{response_policy_rule}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Fetches the representation of an existing Response Policy Rule.
#
# GET /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}
# operationId: dns.responsePolicyRules.get
export def "dns-projects-locations-response-policies-rules get" [
  project: string
  location: string
  response_policy: string
  response_policy_rule: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list<record>>, ruleName: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  if ($response_policy_rule | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicyRule' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy), response_policy_rule: (encode-path-segment $response_policy_rule)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}/rules/{response_policy_rule}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: null}
}

# Applies a partial update to an existing Response Policy Rule.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}
# operationId: dns.responsePolicyRules.patch
# --localData shape: {localDatas?: list}
export def "dns-projects-locations-response-policies-rules update-by-project-location-response-policy-response-policy-rule" [
  project: string
  location: string
  response_policy: string
  response_policy_rule: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --behavior: string@behavior-completer # Answer this query with a behavior rather than DNS data.
  --dns-name: string # The DNS name (wildcard or exact) to apply this rule to. Must be unique within the Response Policy Rule.
  --kind: string # default: dns#responsePolicyRule
  --local-data: record # shape: {localDatas?: list}
  --rule-name: string # An identifier for this rule. Must be unique with the ResponsePolicy.
]: any -> record<header: record<operationId: string>, responsePolicyRule: record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list>, ruleName: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  if ($response_policy_rule | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicyRule' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy), response_policy_rule: (encode-path-segment $response_policy_rule)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}/rules/{response_policy_rule}") $qp)
  let req_body = {"behavior": $behavior, "dnsName": $dns_name, "kind": $kind, "localData": $local_data, "ruleName": $rule_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Updates an existing Response Policy Rule.
#
# PUT /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}
# operationId: dns.responsePolicyRules.update
# --localData shape: {localDatas?: list}
export def "dns-projects-locations-response-policies-rules update-by-project-location-response-policy-response-policy-rule-1" [
  project: string
  location: string
  response_policy: string
  response_policy_rule: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --behavior: string@behavior-completer # Answer this query with a behavior rather than DNS data.
  --dns-name: string # The DNS name (wildcard or exact) to apply this rule to. Must be unique within the Response Policy Rule.
  --kind: string # default: dns#responsePolicyRule
  --local-data: record # shape: {localDatas?: list}
  --rule-name: string # An identifier for this rule. Must be unique with the ResponsePolicy.
]: any -> record<header: record<operationId: string>, responsePolicyRule: record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list>, ruleName: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($response_policy | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicy' must be non-empty" } }
  if ($response_policy_rule | is-empty) { error make --unspanned { msg: "path parameter 'responsePolicyRule' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clientOperationId" $client_operation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), location: (encode-path-segment $location), response_policy: (encode-path-segment $response_policy), response_policy_rule: (encode-path-segment $response_policy_rule)} | format pattern "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{response_policy}/rules/{response_policy_rule}") $qp)
  let req_body = {"behavior": $behavior, "dnsName": $dns_name, "kind": $kind, "localData": $local_data, "ruleName": $rule_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clientOperationId": $client_operation_id} | compact), body: $req_body}
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# POST /dns/v2/{resource}:getIamPolicy
# operationId: dns.managedZones.getIamPolicy
# --options shape: {requestedPolicyVersion?: int}
export def "dns get-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --options: record # Encapsulates settings provided to GetIamPolicy. — shape: {requestedPolicyVersion?: int}
]: any -> record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/dns/v2/{resource}:getIamPolicy") $qp)
  let req_body = {"options": $options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the access control policy on the specified resource. Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`, and `PERMISSION_DENIED` errors.
#
# POST /dns/v2/{resource}:setIamPolicy
# operationId: dns.managedZones.setIamPolicy
# --policy shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
export def "dns update-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: `paths: "bindings, etag"` (format: google-fieldmask)
]: any -> record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/dns/v2/{resource}:setIamPolicy") $qp)
  let req_body = {"policy": $policy, "updateMask": $update_mask} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this returns an empty set of permissions, not a `NOT_FOUND` error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /dns/v2/{resource}:testIamPermissions
# operationId: dns.managedZones.testIamPermissions
export def "dns test-iam-permissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> record<permissions: list<string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o CLOUD_DNS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o CLOUD_DNS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/dns/v2/{resource}:testIamPermissions") $qp)
  let req_body = {"permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}
