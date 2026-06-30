# Auto-generated client for AWS App Mesh v2019-01-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/appmesh/2019-01-25/openapi.json
# Auth: --token flag or $env.AWS_APP_MESH_TOKEN

const BASE_URL = "http://appmesh.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_APP_MESH_TOKEN | default "" }
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

def base-url-completer [] { ["http://appmesh.us-east-1.amazonaws.com" "http://appmesh.us-east-2.amazonaws.com" "http://appmesh.us-west-1.amazonaws.com" "http://appmesh.us-west-2.amazonaws.com" "http://appmesh.us-gov-west-1.amazonaws.com" "http://appmesh.us-gov-east-1.amazonaws.com" "http://appmesh.ca-central-1.amazonaws.com" "http://appmesh.eu-north-1.amazonaws.com" "http://appmesh.eu-west-1.amazonaws.com" "http://appmesh.eu-west-2.amazonaws.com" "http://appmesh.eu-west-3.amazonaws.com" "http://appmesh.eu-central-1.amazonaws.com" "http://appmesh.eu-south-1.amazonaws.com" "http://appmesh.af-south-1.amazonaws.com" "http://appmesh.ap-northeast-1.amazonaws.com" "http://appmesh.ap-northeast-2.amazonaws.com" "http://appmesh.ap-northeast-3.amazonaws.com" "http://appmesh.ap-southeast-1.amazonaws.com" "http://appmesh.ap-southeast-2.amazonaws.com" "http://appmesh.ap-east-1.amazonaws.com" "http://appmesh.ap-south-1.amazonaws.com" "http://appmesh.sa-east-1.amazonaws.com" "http://appmesh.me-south-1.amazonaws.com" "https://appmesh.us-east-1.amazonaws.com" "https://appmesh.us-east-2.amazonaws.com" "https://appmesh.us-west-1.amazonaws.com" "https://appmesh.us-west-2.amazonaws.com" "https://appmesh.us-gov-west-1.amazonaws.com" "https://appmesh.us-gov-east-1.amazonaws.com" "https://appmesh.ca-central-1.amazonaws.com" "https://appmesh.eu-north-1.amazonaws.com" "https://appmesh.eu-west-1.amazonaws.com" "https://appmesh.eu-west-2.amazonaws.com" "https://appmesh.eu-west-3.amazonaws.com" "https://appmesh.eu-central-1.amazonaws.com" "https://appmesh.eu-south-1.amazonaws.com" "https://appmesh.af-south-1.amazonaws.com" "https://appmesh.ap-northeast-1.amazonaws.com" "https://appmesh.ap-northeast-2.amazonaws.com" "https://appmesh.ap-northeast-3.amazonaws.com" "https://appmesh.ap-southeast-1.amazonaws.com" "https://appmesh.ap-southeast-2.amazonaws.com" "https://appmesh.ap-east-1.amazonaws.com" "https://appmesh.ap-south-1.amazonaws.com" "https://appmesh.sa-east-1.amazonaws.com" "https://appmesh.me-south-1.amazonaws.com" "http://appmesh.cn-north-1.amazonaws.com.cn" "http://appmesh.cn-northwest-1.amazonaws.com.cn" "https://appmesh.cn-north-1.amazonaws.com.cn" "https://appmesh.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "meshes-virtual-gateway-gateway-routes create" } } | get name | first)
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

# Creates a gateway route. A gateway route is attached to a virtual gateway and routes traffic to an existing virtual service. If a route matches a request, it can distribute traffic to a target virtual service. For more information about gateway routes, see Gateway routes (https://docs.aws.amazon.com/app-mesh/latest/userguide/gateway-routes.html).
#
# PUT /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes
# operationId: CreateGatewayRoute
# --spec shape: {grpcRoute?: any, http2Route?: any, httpRoute?: any, priority?: any}
# --tags item shape: {key: any, value: any}
export def "meshes-virtual-gateway-gateway-routes create" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  gateway_route_name: string # The name to use for the gateway route.
  spec: record # An object that represents a gateway route specification. Specify one gateway route type. — shape: {grpcRoute?: any, http2Route?: any, httpRoute?: any, priority?: any}
  --tags: list # Optional metadata that you can apply to the gateway route to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: any, value: any}
]: any -> record<gatewayRoute: record<gatewayRouteName: record, meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: record>, status: record<status: record>, virtualGatewayName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_gateway_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualGatewayName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_gateway_name: (encode-path-segment $virtual_gateway_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateway/{virtual_gateway_name}/gatewayRoutes") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "gatewayRouteName": $gateway_route_name, "spec": $spec, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of existing gateway routes that are associated to a virtual gateway.
#
# GET /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes
# operationId: ListGatewayRoutes
export def "meshes-virtual-gateway-gateway-routes list" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListGatewayRoutes in paginated output. When you use this parameter, ListGatewayRoutes returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListGatewayRoutes request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListGatewayRoutes returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListGatewayRoutes request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<gatewayRoutes: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_gateway_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualGatewayName' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "meshOwner" $mesh_owner "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_gateway_name: (encode-path-segment $virtual_gateway_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateway/{virtual_gateway_name}/gatewayRoutes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "meshOwner": $mesh_owner, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a service mesh. A service mesh is a logical boundary for network traffic between services that are represented by resources within the mesh. After you create your service mesh, you can create virtual services, virtual nodes, virtual routers, and routes to distribute traffic between the applications in your mesh. For more information about service meshes, see Service meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/meshes.html).
#
# PUT /v20190125/meshes
# operationId: CreateMesh
# --spec shape: {egressFilter?: any, serviceDiscovery?: record}
# --tags item shape: {key: any, value: any}
export def "meshes create-mesh" [
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
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  mesh_name: string # The name to use for the service mesh.
  --spec: record # An object that represents the specification of a service mesh. — shape: {egressFilter?: any, serviceDiscovery?: record}
  --tags: list # Optional metadata that you can apply to the service mesh to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: any, value: any}
]: any -> record<mesh: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v20190125/meshes" $auth.query)
  let req_body = {"clientToken": $client_token, "meshName": $mesh_name, "spec": $spec, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of existing service meshes.
#
# GET /v20190125/meshes
# operationId: ListMeshes
export def "meshes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListMeshes in paginated output. When you use this parameter, ListMeshes returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListMeshes request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListMeshes returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListMeshes request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<meshes: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20190125/meshes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a route that is associated with a virtual router. You can route several different protocols and define a retry policy for a route. Traffic can be routed to one or more virtual nodes. For more information about routes, see Routes (https://docs.aws.amazon.com/app-mesh/latest/userguide/routes.html).
#
# PUT /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes
# operationId: CreateRoute
# --spec shape: {grpcRoute?: any, http2Route?: any, httpRoute?: any, priority?: any, tcpRoute?: any}
# --tags item shape: {key: any, value: any}
export def "meshes-virtual-router-routes create" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  route_name: string # The name to use for the route.
  spec: record # An object that represents a route specification. Specify one route type. — shape: {grpcRoute?: any, http2Route?: any, httpRoute?: any, priority?: any, tcpRoute?: any}
  --tags: list # Optional metadata that you can apply to the route to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: any, value: any}
]: any -> record<route: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, routeName: record, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: record, tcpRoute: record>, status: record<status: record>, virtualRouterName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_router_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualRouterName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_router_name: (encode-path-segment $virtual_router_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouter/{virtual_router_name}/routes") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "routeName": $route_name, "spec": $spec, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of existing routes in a service mesh.
#
# GET /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes
# operationId: ListRoutes
export def "meshes-virtual-router-routes list" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListRoutes in paginated output. When you use this parameter, ListRoutes returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListRoutes request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListRoutes returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListRoutes request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, routes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_router_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualRouterName' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "meshOwner" $mesh_owner "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_router_name: (encode-path-segment $virtual_router_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouter/{virtual_router_name}/routes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "meshOwner": $mesh_owner, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a virtual gateway. A virtual gateway allows resources outside your mesh to communicate to resources that are inside your mesh. The virtual gateway represents an Envoy proxy running in an Amazon ECS task, in a Kubernetes service, or on an Amazon EC2 instance. Unlike a virtual node, which represents an Envoy running with an application, a virtual gateway represents Envoy deployed by itself. For more information about virtual gateways, see Virtual gateways (https://docs.aws.amazon.com/app-mesh/latest/userguide/virtual_gateways.html).
#
# PUT /v20190125/meshes/{meshName}/virtualGateways
# operationId: CreateVirtualGateway
# --spec shape: {backendDefaults?: any, listeners?: any, logging?: record}
# --tags item shape: {key: any, value: any}
export def "meshes-virtual-gateways create" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a service mesh resource. — shape: {backendDefaults?: any, listeners?: any, logging?: record}
  --tags: list # Optional metadata that you can apply to the virtual gateway to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: any, value: any}
  virtual_gateway_name: string # The name to use for the virtual gateway.
]: any -> record<virtualGateway: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<backendDefaults: record, listeners: record, logging: record>, status: record<status: record>, virtualGatewayName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateways") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec, "tags": $tags, "virtualGatewayName": $virtual_gateway_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of existing virtual gateways in a service mesh.
#
# GET /v20190125/meshes/{meshName}/virtualGateways
# operationId: ListVirtualGateways
export def "meshes-virtual-gateways list" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListVirtualGateways in paginated output. When you use this parameter, ListVirtualGateways returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListVirtualGateways request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListVirtualGateways returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListVirtualGateways request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, virtualGateways: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "meshOwner" $mesh_owner "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateways") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "meshOwner": $mesh_owner, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a virtual node within a service mesh. A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS service or a Kubernetes deployment. When you create a virtual node, you can specify the service discovery information for your task group, and whether the proxy running in a task group will communicate with other proxies using Transport Layer Security (TLS). You define a listener for any inbound traffic that your virtual node expects. Any virtual service that your virtual node expects to communicate to is specified as a backend. The response metadata for your new virtual node contains the arn that is associated with the virtual node. Set this value to the full ARN; for example, arn:aws:appmesh:us-west-2:123456789012:myMesh/default/virtualNode/myApp) as the APPMESH_RESOURCE_ARN environment variable for your task group's Envoy proxy container in your task definition or pod spec. This is then mapped to the node.id and node.cluster Envoy parameters. By default, App Mesh uses the name of the resource you specified in APPMESH_RESOURCE_ARN when Envoy is referring to itself in metrics and traces. You can override this behavior by setting the APPMESH_RESOURCE_CLUSTER environment variable with your own name. For more information about virtual nodes, see Virtual nodes (https://docs.aws.amazon.com/app-mesh/latest/userguide/virtual_nodes.html). You must be using 1.15.0 or later of the Envoy image when setting these variables. For more information aboutApp Mesh Envoy variables, see Envoy image (https://docs.aws.amazon.com/app-mesh/latest/userguide/envoy.html) in the App Mesh User Guide.
#
# PUT /v20190125/meshes/{meshName}/virtualNodes
# operationId: CreateVirtualNode
# --spec shape: {backendDefaults?: any, backends?: any, listeners?: any, logging?: any, serviceDiscovery?: any}
# --tags item shape: {key: any, value: any}
export def "meshes-virtual-nodes create" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual node. — shape: {backendDefaults?: any, backends?: any, listeners?: any, logging?: any, serviceDiscovery?: any}
  --tags: list # Optional metadata that you can apply to the virtual node to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: any, value: any}
  virtual_node_name: string # The name to use for the virtual node.
]: any -> record<virtualNode: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<backendDefaults: record, backends: record, listeners: record, logging: record, serviceDiscovery: record>, status: record<status: record>, virtualNodeName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualNodes") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec, "tags": $tags, "virtualNodeName": $virtual_node_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of existing virtual nodes.
#
# GET /v20190125/meshes/{meshName}/virtualNodes
# operationId: ListVirtualNodes
export def "meshes-virtual-nodes list" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListVirtualNodes in paginated output. When you use this parameter, ListVirtualNodes returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListVirtualNodes request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListVirtualNodes returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListVirtualNodes request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, virtualNodes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "meshOwner" $mesh_owner "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualNodes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "meshOwner": $mesh_owner, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a virtual router within a service mesh. Specify a listener for any inbound traffic that your virtual router receives. Create a virtual router for each protocol and port that you need to route. Virtual routers handle traffic for one or more virtual services within your mesh. After you create your virtual router, create and associate routes for your virtual router that direct incoming requests to different virtual nodes. For more information about virtual routers, see Virtual routers (https://docs.aws.amazon.com/app-mesh/latest/userguide/virtual_routers.html).
#
# PUT /v20190125/meshes/{meshName}/virtualRouters
# operationId: CreateVirtualRouter
# --spec shape: {listeners?: any}
# --tags item shape: {key: any, value: any}
export def "meshes-virtual-routers create" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual router. — shape: {listeners?: any}
  --tags: list # Optional metadata that you can apply to the virtual router to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: any, value: any}
  virtual_router_name: string # The name to use for the virtual router.
]: any -> record<virtualRouter: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<listeners: record>, status: record<status: record>, virtualRouterName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouters") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec, "tags": $tags, "virtualRouterName": $virtual_router_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of existing virtual routers in a service mesh.
#
# GET /v20190125/meshes/{meshName}/virtualRouters
# operationId: ListVirtualRouters
export def "meshes-virtual-routers list" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListVirtualRouters in paginated output. When you use this parameter, ListVirtualRouters returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListVirtualRouters request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListVirtualRouters returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListVirtualRouters request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, virtualRouters: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "meshOwner" $mesh_owner "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouters") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "meshOwner": $mesh_owner, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a virtual service within a service mesh. A virtual service is an abstraction of a real service that is provided by a virtual node directly or indirectly by means of a virtual router. Dependent services call your virtual service by its virtualServiceName, and those requests are routed to the virtual node or virtual router that is specified as the provider for the virtual service. For more information about virtual services, see Virtual services (https://docs.aws.amazon.com/app-mesh/latest/userguide/virtual_services.html).
#
# PUT /v20190125/meshes/{meshName}/virtualServices
# operationId: CreateVirtualService
# --spec shape: {provider?: any}
# --tags item shape: {key: any, value: any}
export def "meshes-virtual-services create" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then the account that you specify must share the mesh with your account before you can create the resource in the service mesh. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual service. — shape: {provider?: any}
  --tags: list # Optional metadata that you can apply to the virtual service to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: any, value: any}
  virtual_service_name: string # The name to use for the virtual service.
]: any -> record<virtualService: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<provider: record>, status: record<status: record>, virtualServiceName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualServices") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec, "tags": $tags, "virtualServiceName": $virtual_service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of existing virtual services in a service mesh.
#
# GET /v20190125/meshes/{meshName}/virtualServices
# operationId: ListVirtualServices
export def "meshes-virtual-services list" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results returned by ListVirtualServices in paginated output. When you use this parameter, ListVirtualServices returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListVirtualServices request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListVirtualServices returns up to 100 results and a nextToken value if applicable.
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --next-token: string # The nextToken value returned from a previous paginated ListVirtualServices request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, virtualServices: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "meshOwner" $mesh_owner "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualServices") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "meshOwner": $mesh_owner, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an existing gateway route.
#
# DELETE /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes/{gatewayRouteName}
# operationId: DeleteGatewayRoute
export def "meshes-virtual-gateway-gateway-routes delete" [
  mesh_name: string
  virtual_gateway_name: string
  gateway_route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<gatewayRoute: record<gatewayRouteName: record, meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: record>, status: record<status: record>, virtualGatewayName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_gateway_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualGatewayName' must be non-empty" } }
  if ($gateway_route_name | is-empty) { error make --unspanned { msg: "path parameter 'gatewayRouteName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_gateway_name: (encode-path-segment $virtual_gateway_name), gateway_route_name: (encode-path-segment $gateway_route_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateway/{virtual_gateway_name}/gatewayRoutes/{gateway_route_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Describes an existing gateway route.
#
# GET /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes/{gatewayRouteName}
# operationId: DescribeGatewayRoute
export def "meshes-virtual-gateway-gateway-routes get" [
  mesh_name: string
  virtual_gateway_name: string
  gateway_route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<gatewayRoute: record<gatewayRouteName: record, meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: record>, status: record<status: record>, virtualGatewayName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_gateway_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualGatewayName' must be non-empty" } }
  if ($gateway_route_name | is-empty) { error make --unspanned { msg: "path parameter 'gatewayRouteName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_gateway_name: (encode-path-segment $virtual_gateway_name), gateway_route_name: (encode-path-segment $gateway_route_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateway/{virtual_gateway_name}/gatewayRoutes/{gateway_route_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing gateway route that is associated to a specified virtual gateway in a service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualGateway/{virtualGatewayName}/gatewayRoutes/{gatewayRouteName}
# operationId: UpdateGatewayRoute
# --spec shape: {grpcRoute?: any, http2Route?: any, httpRoute?: any, priority?: any}
export def "meshes-virtual-gateway-gateway-routes update" [
  mesh_name: string
  virtual_gateway_name: string
  gateway_route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents a gateway route specification. Specify one gateway route type. — shape: {grpcRoute?: any, http2Route?: any, httpRoute?: any, priority?: any}
]: any -> record<gatewayRoute: record<gatewayRouteName: record, meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: record>, status: record<status: record>, virtualGatewayName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_gateway_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualGatewayName' must be non-empty" } }
  if ($gateway_route_name | is-empty) { error make --unspanned { msg: "path parameter 'gatewayRouteName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_gateway_name: (encode-path-segment $virtual_gateway_name), gateway_route_name: (encode-path-segment $gateway_route_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateway/{virtual_gateway_name}/gatewayRoutes/{gateway_route_name}") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing service mesh. You must delete all resources (virtual services, routes, virtual routers, and virtual nodes) in the service mesh before you can delete the mesh itself.
#
# DELETE /v20190125/meshes/{meshName}
# operationId: DeleteMesh
export def "meshes delete-mesh" [
  mesh_name: string
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
]: nothing -> record<mesh: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}") $auth.query)
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

# Describes an existing service mesh.
#
# GET /v20190125/meshes/{meshName}
# operationId: DescribeMesh
export def "meshes get-mesh" [
  mesh_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<mesh: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing service mesh.
#
# PUT /v20190125/meshes/{meshName}
# operationId: UpdateMesh
# --spec shape: {egressFilter?: any, serviceDiscovery?: record}
export def "meshes update-mesh" [
  mesh_name: string
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
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  --spec: record # An object that represents the specification of a service mesh. — shape: {egressFilter?: any, serviceDiscovery?: record}
]: any -> record<mesh: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<egressFilter: record, serviceDiscovery: record>, status: record<status: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name)} | format pattern "/v20190125/meshes/{mesh_name}") $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing route.
#
# DELETE /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}
# operationId: DeleteRoute
export def "meshes-virtual-router-routes delete" [
  mesh_name: string
  virtual_router_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<route: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, routeName: record, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: record, tcpRoute: record>, status: record<status: record>, virtualRouterName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_router_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualRouterName' must be non-empty" } }
  if ($route_name | is-empty) { error make --unspanned { msg: "path parameter 'routeName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_router_name: (encode-path-segment $virtual_router_name), route_name: (encode-path-segment $route_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouter/{virtual_router_name}/routes/{route_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Describes an existing route.
#
# GET /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}
# operationId: DescribeRoute
export def "meshes-virtual-router-routes get" [
  mesh_name: string
  virtual_router_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<route: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, routeName: record, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: record, tcpRoute: record>, status: record<status: record>, virtualRouterName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_router_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualRouterName' must be non-empty" } }
  if ($route_name | is-empty) { error make --unspanned { msg: "path parameter 'routeName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_router_name: (encode-path-segment $virtual_router_name), route_name: (encode-path-segment $route_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouter/{virtual_router_name}/routes/{route_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing route for a specified service mesh and virtual router.
#
# PUT /v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}
# operationId: UpdateRoute
# --spec shape: {grpcRoute?: any, http2Route?: any, httpRoute?: any, priority?: any, tcpRoute?: any}
export def "meshes-virtual-router-routes update" [
  mesh_name: string
  virtual_router_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents a route specification. Specify one route type. — shape: {grpcRoute?: any, http2Route?: any, httpRoute?: any, priority?: any, tcpRoute?: any}
]: any -> record<route: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, routeName: record, spec: record<grpcRoute: record, http2Route: record, httpRoute: record, priority: record, tcpRoute: record>, status: record<status: record>, virtualRouterName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_router_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualRouterName' must be non-empty" } }
  if ($route_name | is-empty) { error make --unspanned { msg: "path parameter 'routeName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_router_name: (encode-path-segment $virtual_router_name), route_name: (encode-path-segment $route_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouter/{virtual_router_name}/routes/{route_name}") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing virtual gateway. You cannot delete a virtual gateway if any gateway routes are associated to it.
#
# DELETE /v20190125/meshes/{meshName}/virtualGateways/{virtualGatewayName}
# operationId: DeleteVirtualGateway
export def "meshes-virtual-gateways delete" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<virtualGateway: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<backendDefaults: record, listeners: record, logging: record>, status: record<status: record>, virtualGatewayName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_gateway_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualGatewayName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_gateway_name: (encode-path-segment $virtual_gateway_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateways/{virtual_gateway_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Describes an existing virtual gateway.
#
# GET /v20190125/meshes/{meshName}/virtualGateways/{virtualGatewayName}
# operationId: DescribeVirtualGateway
export def "meshes-virtual-gateways get" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<virtualGateway: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<backendDefaults: record, listeners: record, logging: record>, status: record<status: record>, virtualGatewayName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_gateway_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualGatewayName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_gateway_name: (encode-path-segment $virtual_gateway_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateways/{virtual_gateway_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing virtual gateway in a specified service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualGateways/{virtualGatewayName}
# operationId: UpdateVirtualGateway
# --spec shape: {backendDefaults?: any, listeners?: any, logging?: record}
export def "meshes-virtual-gateways update" [
  mesh_name: string
  virtual_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a service mesh resource. — shape: {backendDefaults?: any, listeners?: any, logging?: record}
]: any -> record<virtualGateway: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<backendDefaults: record, listeners: record, logging: record>, status: record<status: record>, virtualGatewayName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_gateway_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualGatewayName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_gateway_name: (encode-path-segment $virtual_gateway_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualGateways/{virtual_gateway_name}") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing virtual node. You must delete any virtual services that list a virtual node as a service provider before you can delete the virtual node itself.
#
# DELETE /v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}
# operationId: DeleteVirtualNode
export def "meshes-virtual-nodes delete" [
  mesh_name: string
  virtual_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<virtualNode: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<backendDefaults: record, backends: record, listeners: record, logging: record, serviceDiscovery: record>, status: record<status: record>, virtualNodeName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_node_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualNodeName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_node_name: (encode-path-segment $virtual_node_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualNodes/{virtual_node_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Describes an existing virtual node.
#
# GET /v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}
# operationId: DescribeVirtualNode
export def "meshes-virtual-nodes get" [
  mesh_name: string
  virtual_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<virtualNode: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<backendDefaults: record, backends: record, listeners: record, logging: record, serviceDiscovery: record>, status: record<status: record>, virtualNodeName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_node_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualNodeName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_node_name: (encode-path-segment $virtual_node_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualNodes/{virtual_node_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing virtual node in a specified service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}
# operationId: UpdateVirtualNode
# --spec shape: {backendDefaults?: any, backends?: any, listeners?: any, logging?: any, serviceDiscovery?: any}
export def "meshes-virtual-nodes update" [
  mesh_name: string
  virtual_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual node. — shape: {backendDefaults?: any, backends?: any, listeners?: any, logging?: any, serviceDiscovery?: any}
]: any -> record<virtualNode: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<backendDefaults: record, backends: record, listeners: record, logging: record, serviceDiscovery: record>, status: record<status: record>, virtualNodeName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_node_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualNodeName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_node_name: (encode-path-segment $virtual_node_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualNodes/{virtual_node_name}") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing virtual router. You must delete any routes associated with the virtual router before you can delete the router itself.
#
# DELETE /v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}
# operationId: DeleteVirtualRouter
export def "meshes-virtual-routers delete" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<virtualRouter: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<listeners: record>, status: record<status: record>, virtualRouterName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_router_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualRouterName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_router_name: (encode-path-segment $virtual_router_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouters/{virtual_router_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Describes an existing virtual router.
#
# GET /v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}
# operationId: DescribeVirtualRouter
export def "meshes-virtual-routers get" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<virtualRouter: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<listeners: record>, status: record<status: record>, virtualRouterName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_router_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualRouterName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_router_name: (encode-path-segment $virtual_router_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouters/{virtual_router_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing virtual router in a specified service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}
# operationId: UpdateVirtualRouter
# --spec shape: {listeners?: any}
export def "meshes-virtual-routers update" [
  mesh_name: string
  virtual_router_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual router. — shape: {listeners?: any}
]: any -> record<virtualRouter: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<listeners: record>, status: record<status: record>, virtualRouterName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_router_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualRouterName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_router_name: (encode-path-segment $virtual_router_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualRouters/{virtual_router_name}") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing virtual service.
#
# DELETE /v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}
# operationId: DeleteVirtualService
export def "meshes-virtual-services delete" [
  mesh_name: string
  virtual_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<virtualService: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<provider: record>, status: record<status: record>, virtualServiceName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_service_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualServiceName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_service_name: (encode-path-segment $virtual_service_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualServices/{virtual_service_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Describes an existing virtual service.
#
# GET /v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}
# operationId: DescribeVirtualService
export def "meshes-virtual-services get" [
  mesh_name: string
  virtual_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<virtualService: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<provider: record>, status: record<status: record>, virtualServiceName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_service_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualServiceName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_service_name: (encode-path-segment $virtual_service_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualServices/{virtual_service_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing virtual service in a specified service mesh.
#
# PUT /v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}
# operationId: UpdateVirtualService
# --spec shape: {provider?: any}
export def "meshes-virtual-services update" [
  mesh_name: string
  virtual_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mesh-owner: string # The Amazon Web Services IAM account ID of the service mesh owner. If the account ID is not your own, then it's the ID of the account that shared the mesh with your account. For more information about mesh sharing, see Working with shared meshes (https://docs.aws.amazon.com/app-mesh/latest/userguide/sharing.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Up to 36 letters, numbers, hyphens, and underscores are allowed.
  spec: record # An object that represents the specification of a virtual service. — shape: {provider?: any}
]: any -> record<virtualService: record<meshName: record, metadata: record<arn: record, createdAt: record, lastUpdatedAt: record, meshOwner: record, resourceOwner: record, uid: record, version: record>, spec: record<provider: record>, status: record<status: record>, virtualServiceName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mesh_name | is-empty) { error make --unspanned { msg: "path parameter 'meshName' must be non-empty" } }
  if ($virtual_service_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualServiceName' must be non-empty" } }
  let qp = [(serialize-qp "meshOwner" $mesh_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mesh_name: (encode-path-segment $mesh_name), virtual_service_name: (encode-path-segment $virtual_service_name)} | format pattern "/v20190125/meshes/{mesh_name}/virtualServices/{virtual_service_name}") $qp $auth.query)
  let req_body = {"clientToken": $client_token, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"meshOwner": $mesh_owner} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List the tags for an App Mesh resource.
#
# GET /v20190125/tags
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of tag results returned by ListTagsForResource in paginated output. When this parameter is used, ListTagsForResource returns only limit results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListTagsForResource request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListTagsForResource returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListTagsForResource request where limit was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --resource-arn: string # The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "resourceArn" $resource_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20190125/tags" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "nextToken": $next_token, "resourceArn": $resource_arn} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource aren't specified in the request parameters, they aren't changed. When a resource is deleted, the tags associated with that resource are also deleted.
#
# PUT /v20190125/tag
# operationId: TagResource
# --tags item shape: {key: any, value: any}
export def "tag tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource to add tags to.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: list # The tags to add to the resource. A tag is an array of key-value pairs. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters. — item shape: {key: any, value: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceArn" $resource_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20190125/tag" $qp $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"resourceArn": $resource_arn} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes specified tags from a resource.
#
# PUT /v20190125/untag
# operationId: UntagResource
export def "untag untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource to delete tags from.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tag_keys: list<string> # The keys of the tags to be removed.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceArn" $resource_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v20190125/untag" $qp $auth.query)
  let req_body = {"tagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"resourceArn": $resource_arn} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}
