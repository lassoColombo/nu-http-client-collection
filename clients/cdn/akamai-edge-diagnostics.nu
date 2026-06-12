# Auto-generated client for Akamai: Edge Diagnostics API vv1
# Source: https://raw.githubusercontent.com/akamai/akamai-apis/main/apis/edge-diagnostics/v1/openapi.json
# Auth: --token flag or $env.AKAMAI_EDGE_DIAGNOSTICS_API_TOKEN

const BASE_URL = "https://{hostname}/edge-diagnostics/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AKAMAI_EDGE_DIAGNOSTICS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["https://{hostname}/edge-diagnostics/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ipVersion-completer [] { ["IPV4" "IPV6"] }
def packetType-completer [] { ["ICMP" "TCP"] }
def port-completer [] { ["443" "80"] }
def queryType-completer [] { ["A" "AAAA" "ANY" "CAA" "CNAME" "MX" "NS" "PTR" "SOA" "SRV" "TXT"] }
def delivery-completer [] { ["ENHANCED_TLS" "STANDARD_TLS"] }
def errorType-completer [] { ["EDGE_ERRORS" "ORIGIN_ERRORS"] }
def logType-completer [] { ["BOTH" "F" "R"] }
def logType-completer-1 [] { ["F" "R"] }
def httpMethod-completer [] { ["GET" "HEAD" "POST"] }
def accept-completer [] { ["application/json" "text/html"] }
def destinationType-completer [] { ["HOST" "IP"] }
def sourceType-completer [] { ["EDGE_IP" "LOCATION"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "connectivity-problems post-connectivity-problems" } } | get name | first)
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

# Run the connectivity problems scenario
#
# POST /connectivity-problems
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-connectivity-problems — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-connectivity-problems
export def "connectivity-problems post-connectivity-problems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --clientIp: string # Client IP for the Connectivity problems scenario to start MTR from. You can use the `ip` value from the `edgeIps` array in the [collected diagnostic data](https://techdocs.akamai.com/edge-diagnostics/reference/get-user-diagnostic-data-group-records). (e.g. {{clientIp}})
  --edgeLocationId: string # Unique identifier for an edge server location closest to end users experiencing issues with the URL. Run the [List available edge server locations](https://techdocs.akamai.com/edge-diagnostics/reference/get-edge-locations) operation to get this value. (e.g. {{edgeLocationId}})
  --ipVersion: string@ipVersion-completer # IP version for the Connectivity problems scenario to use to run cURL and MTR commands, either `IPV4` or `IPV6`. (e.g. {{ipVersion}})
  --packetType: string@packetType-completer # Packet type for the Connectivity problems scenario to use to run MTR, either `ICMP` or `TCP`. (e.g. {{packetType}})
  --port: int@port-completer # Port number for the Connectivity problems scenario to use to run MTR, either `80` or `443`. (e.g. {{port}})
  --requestHeaders: list # Customized headers for the `curl` request in the format `header: value`. The request includes [Akamai Pragma headers](https://techdocs.akamai.com/edge-diagnostics/docs/pragma-headers) by default.
  --runFromSiteShield: oneof<nothing, bool> # Runs Connectivity problems from a Site Shield map. To learn more, check [Site Shield requests](https://techdocs.akamai.com/edge-diagnostics/reference/site-shield-requests). (e.g. {{runFromSiteShield}})
  --sensitiveRequestHeaderKeys: list # Sensitive `requestHeaders` you don't want to store in the database after running the request. Check [Sensitive headers](https://techdocs.akamai.com/edge-diagnostics/reference/sensitive-headers) to see the list of request headers treated as sensitive by default.
  --spoofEdgeIp: string # IP of the edge server you want to serve traffic from. You can use the `ip` value from the `edgeIps` array in the [collected diagnostic data](https://techdocs.akamai.com/edge-diagnostics/reference/get-user-diagnostic-data-group-records). (e.g. {{spoofEdgeIp}})
  --body-url: string # URL you want to run the Connectivity problems scenario for. (format: uri, e.g. {{url}})
]: any -> record<clientIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, connectivity: table<additionalRequestParameters: record, destinationContext: string, destinationIpLocation: record, errorResponse: record, executionContext: string, executionStatus: string, info: record, result: record, sourceContext: string, sourceIpLocation: record, suggestedActions: list>, content: table<additionalRequestParameters: record, errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, createdBy: string, createdTime: string, errorResponse: record<detail: string, errors: list<string>, status: string, title: string, type: string>, executionStatus: string, internalIp: string, internalIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, link: string, logLines: table<errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, request: record<clientIp: string, edgeLocationId: string, ipVersion: string, packetType: string, port: int, requestHeaders: list<string>, runFromSiteShield: bool, sensitiveRequestHeaderKeys: list<string>, spoofEdgeIp: string, url: string>, requestId: int, retryAfter: int, siteShieldIp: string, siteShieldIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, spoofEdgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, summary: record<connectivity: list<record>, content: list<record>, logLines: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connectivity-problems" $qp)
  let body = {clientIp: $clientIp, edgeLocationId: $edgeLocationId, ipVersion: $ipVersion, packetType: $packetType, port: $port, requestHeaders: $requestHeaders, runFromSiteShield: $runFromSiteShield, sensitiveRequestHeaderKeys: $sensitiveRequestHeaderKeys, spoofEdgeIp: $spoofEdgeIp, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the Connectivity problems scenario response
#
# GET /connectivity-problems/requests/{requestId}
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-connectivity-problems-request — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-connectivity-problems-request
export def "connectivity-problems-requests get-connectivity-problems-request" [
  requestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeContentResponseBody: oneof<nothing, bool> # Includes response bodies in the response. (e.g. false)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<clientIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, connectivity: table<additionalRequestParameters: record, destinationContext: string, destinationIpLocation: record, errorResponse: record, executionContext: string, executionStatus: string, info: record, result: record, sourceContext: string, sourceIpLocation: record, suggestedActions: list>, content: table<additionalRequestParameters: record, errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, createdBy: string, createdTime: string, errorResponse: record<detail: string, errors: list<string>, status: string, title: string, type: string>, executionStatus: string, internalIp: string, internalIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, link: string, logLines: table<errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, request: record<clientIp: string, edgeLocationId: string, ipVersion: string, packetType: string, port: int, requestHeaders: list<string>, runFromSiteShield: bool, sensitiveRequestHeaderKeys: list<string>, spoofEdgeIp: string, url: string>, requestId: int, retryAfter: int, siteShieldIp: string, siteShieldIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, spoofEdgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, summary: record<connectivity: list<record>, content: list<record>, logLines: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeContentResponseBody" $includeContentResponseBody "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/connectivity-problems/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run the content problems scenario
#
# POST /content-problems
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-content-problems — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-content-problems
export def "content-problems post-content-problems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --edgeLocationId: string # Unique identifier for an edge server location closest to end users experiencing issues with the URL. Run the [List available edge server locations](https://techdocs.akamai.com/edge-diagnostics/reference/get-edge-locations) operation to get this value. (e.g. {{edgeLocationId}})
  --ipVersion: string@ipVersion-completer # IP version for the Content problems scenario to use to run cURL and MTR commands, either `IPV4` or `IPV6`. (e.g. {{ipVersion}})
  --requestHeaders: list # Customized headers for the `curl` request in the format `header: value`. The request includes [Akamai Pragma headers](https://techdocs.akamai.com/edge-diagnostics/docs/pragma-headers) by default.
  --runFromSiteShield: oneof<nothing, bool> # Runs Content problems from a Site Shield map. To learn more, check [Site Shield requests](https://techdocs.akamai.com/edge-diagnostics/reference/site-shield-requests). (e.g. {{runFromSiteShield}})
  --sensitiveRequestHeaderKeys: list # Sensitive `requestHeaders` you don't want to store in the database after running the request. Check [Sensitive headers](https://techdocs.akamai.com/edge-diagnostics/reference/sensitive-headers) to see the list of request headers treated as sensitive by default.
  --spoofEdgeIp: string # IP of the edge server you want to serve traffic from. You can use the `ip` value from the `edgeIps` array in the [collected diagnostic data](https://techdocs.akamai.com/edge-diagnostics/reference/get-user-diagnostic-data-group-records). (e.g. {{spoofEdgeIp}})
  --body-url: string # URL you want to run the Content problems scenario for. (format: uri, e.g. {{url}})
]: any -> record<content: table<additionalRequestParameters: record, errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, createdBy: string, createdTime: string, errorResponse: record<detail: string, errors: list<string>, status: string, title: string, type: string>, executionStatus: string, internalIp: string, internalIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, link: string, logLines: table<errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, request: record<edgeLocationId: string, ipVersion: string, requestHeaders: list<string>, runFromSiteShield: bool, sensitiveRequestHeaderKeys: list<string>, spoofEdgeIp: string, url: string>, requestId: int, retryAfter: int, siteShieldIp: string, siteShieldIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, spoofEdgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, summary: record<content: list<record>, logLines: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/content-problems" $qp)
  let body = {edgeLocationId: $edgeLocationId, ipVersion: $ipVersion, requestHeaders: $requestHeaders, runFromSiteShield: $runFromSiteShield, sensitiveRequestHeaderKeys: $sensitiveRequestHeaderKeys, spoofEdgeIp: $spoofEdgeIp, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the Content problems scenario response
#
# GET /content-problems/requests/{requestId}
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-content-problems — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-content-problems
export def "content-problems-requests get-content-problems" [
  requestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeContentResponseBody: oneof<nothing, bool> # Includes response bodies in the response. (e.g. false)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<content: table<additionalRequestParameters: record, errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, createdBy: string, createdTime: string, errorResponse: record<detail: string, errors: list<string>, status: string, title: string, type: string>, executionStatus: string, internalIp: string, internalIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, link: string, logLines: table<errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, request: record<edgeLocationId: string, ipVersion: string, requestHeaders: list<string>, runFromSiteShield: bool, sensitiveRequestHeaderKeys: list<string>, spoofEdgeIp: string, url: string>, requestId: int, retryAfter: int, siteShieldIp: string, siteShieldIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, spoofEdgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, summary: record<content: list<record>, logLines: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeContentResponseBody" $includeContentResponseBody "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/content-problems/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request content with cURL
#
# POST /curl
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-curl — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-curl
export def "curl post-curl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --edgeIp: string # IP of the edge server you want to run the operation from. If you don't know if an IP is the edge IP, run the [Verify an IP](https://techdocs.akamai.com/edge-diagnostics/reference/post-verify-edge-ip) operation. You need to provide either this value or `edgeLocationId`. (e.g. {{edgeIp}})
  --edgeLocationId: string # Unique identifier for an edge server location closest to your end users. To get this value, run the [List available edge server locations](https://techdocs.akamai.com/edge-diagnostics/reference/get-edge-locations) operation first. You need to provide either this value or `edgeIp`. (e.g. {{edgeLocationId}})
  --ipVersion: string@ipVersion-completer # IP version to use to run the operation, either `IPV4` or `IPV6`. (e.g. {{ipVersion}})
  --requestHeaders: list # Customized headers for `curl` request in the format `header: value`. Check [Pragma headers](https://techdocs.akamai.com/edge-diagnostics/docs/pragma-headers) for the list of Akamaized Pragma headers you can use here.
  --runFromSiteShield: oneof<nothing, bool> # Runs `curl` from a Site Shield map. To learn more, check [Site Shield requests](https://techdocs.akamai.com/edge-diagnostics/reference/site-shield-requests). (e.g. {{runFromSiteShield}})
  --sensitiveRequestHeaderKeys: list # Sensitive `requestHeaders` you don't want to store in the database after running the request. Check [Sensitive headers](https://techdocs.akamai.com/edge-diagnostics/reference/sensitive-headers) to see the list of request headers treated as sensitive by default.
  --spoofEdgeIp: string # IP of the edge server you want to serve traffic from. (e.g. {{spoofEdgeIp}})
  --body-url: string # URL you want to get the raw HTML for. (format: uri, e.g. {{url}})
]: any -> record<completedTime: string, createdBy: string, createdTime: string, edgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, executionStatus: string, internalIp: string, request: record<edgeIp: string, edgeLocationId: string, ipVersion: string, requestHeaders: list<string>, runFromSiteShield: bool, sensitiveRequestHeaderKeys: list<string>, spoofEdgeIp: string, url: string>, result: record<exitCode: int, httpStatusCode: int, httpVersion: string, reasonPhrase: string, responseBody: string, responseHeaderList: list<string>, timing: record<dnsLookupTime: float, sslConnectionTime: float, tcpConnectionTime: float, timeToFirstByte: float, totalTime: float>>, siteShieldIp: string, siteShieldIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, suggestedActions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/curl" $qp)
  let body = {edgeIp: $edgeIp, edgeLocationId: $edgeLocationId, ipVersion: $ipVersion, requestHeaders: $requestHeaders, runFromSiteShield: $runFromSiteShield, sensitiveRequestHeaderKeys: $sensitiveRequestHeaderKeys, spoofEdgeIp: $spoofEdgeIp, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get domain details with dig
#
# POST /dig
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-dig — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-dig
export def "dig post-dig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --edgeIp: string # IP of an edge server you want to run the `dig` command from. Provide either this value or `edgeLocationId`. To verify if an IP belongs to an edge server, run the [Verify an IP](https://techdocs.akamai.com/edge-diagnostics/reference/post-verify-edge-ip) operation. (e.g. {{edgeIp}})
  --edgeLocationId: string # Unique identifier for an edge server location closest to your end users. Provide either this value or `edgeIp`. To get this value, run the [List available edge server locations](https://techdocs.akamai.com/edge-diagnostics/reference/get-edge-locations) operation first. (e.g. {{edgeLocationId}})
  hostname: string # Hostname or a domain name you want to get the data for. For a GTM hostname, run the [List GTM properties](https://techdocs.akamai.com/edge-diagnostics/reference/get-gtm-properties) operation first, to get this value. (format: hostname, e.g. {{hostname}})
  --isGtmHostname: oneof<nothing, bool> # Specifies `hostname` is a GTM hostname. (e.g. {{isGtmHostname}})
  queryType: string@queryType-completer # DNS record type you want to get. Possible values are: `A`, `AAAA`, `SOA`, `CNAME`, `PTR`, `MX`, `NS`, `TXT`, `SRV`, `CAA`, and `ANY`. To learn more about them, check [Supported DNS record types](https://techdocs.akamai.com/edge-diagnostics/docs/domain-details-dig#supported-dns-record-types). (e.g. {{queryType}})
]: any -> record<completedTime: string, createdBy: string, createdTime: string, edgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, executionStatus: string, internalIp: string, request: record<edgeIp: string, edgeLocationId: string, hostname: string, isGtmHostname: bool, queryType: string>, result: record<answerSection: list<record>, authoritySection: list<record>, result: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dig" $qp)
  let body = {edgeIp: $edgeIp, edgeLocationId: $edgeLocationId, hostname: $hostname, isGtmHostname: $isGtmHostname, queryType: $queryType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List available edge server locations
#
# GET /edge-locations
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-edge-locations — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-edge-locations
export def "edge-locations get-edge-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<edgeLocations: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge-locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Translate error string
#
# POST /error-translator
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-error-translator — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-error-translator
export def "error-translator post-error-translator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  errorCode: string # Alphanumeric part of the error reference code you want to get the data for. (e.g. {{errorCode}})
  --traceForwardLogs: oneof<nothing, bool> # Gets logs from all edge servers involved in serving the request. When `false`, you get logs only from the edge server where the error occurred. Tracing forward logs may prolong the time of fetching data. The default value is `false`. (e.g. {{traceForwardLogs}})
]: any -> record<completedTime: string, createdBy: string, createdTime: string, executionStatus: string, link: string, request: record<errorCode: string, traceForwardLogs: bool>, requestId: int, result: record<cacheKeyHostname: string, certificateErrorDetails: record<error: string, fingerPrint: string, solution: string>, clientIp: record<ip: string, ipLocation: record>, clientRequestMethod: string, connectingIp: record<ip: string, ipLocation: record>, cpCode: int, date: string, edgeServerIp: record<ip: string, ipLocation: record>, epochTime: int, grepUrl: string, httpResponseCode: int, logLines: record<legend: record, logs: list>, noLogsErrorTitle: string, noLogsErrorType: string, originIp: record<ip: string, ipLocation: record>, propertyName: string, propertyUrl: string, reasonForFailure: string, url: string, userAgent: string, wafDetails: string, wafDetailsUrl: string, wsaUrl: string>, retryAfter: int, suggestedActions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/error-translator" $qp)
  let body = {errorCode: $errorCode, traceForwardLogs: $traceForwardLogs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a translate error string response
#
# GET /error-translator/requests/{requestId}
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-error-translator-request — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-error-translator-request
export def "error-translator-requests get-error-translator-request" [
  requestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<completedTime: string, createdBy: string, createdTime: string, executionStatus: string, link: string, request: record<errorCode: string, traceForwardLogs: bool>, requestId: int, result: record<cacheKeyHostname: string, certificateErrorDetails: record<error: string, fingerPrint: string, solution: string>, clientIp: record<ip: string, ipLocation: record>, clientRequestMethod: string, connectingIp: record<ip: string, ipLocation: record>, cpCode: int, date: string, edgeServerIp: record<ip: string, ipLocation: record>, epochTime: int, grepUrl: string, httpResponseCode: int, logLines: record<legend: record, logs: list>, noLogsErrorTitle: string, noLogsErrorType: string, originIp: record<ip: string, ipLocation: record>, propertyName: string, propertyUrl: string, reasonForFailure: string, url: string, userAgent: string, wafDetails: string, wafDetailsUrl: string, wsaUrl: string>, retryAfter: int, suggestedActions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/error-translator/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an ESI debugging report
#
# POST /esi-debugger-api/v1/debug
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-debug — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-debug
export def "esi-debugger-api-debug post-debug" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --clientIP: string # The client IP that emulates a location for specific EdgeScape GEO (geographic) data. (e.g. {{clientIP}})
  --clientRequestHeaders: record # Custom HTTP headers used in the client's requests.
  --originServer: string # The test origin server where the edge server sends requests instead of the origin server. (e.g. {{originServer}})
  --body-url: string # The URL of the page with the ESI tags for which you request debugging information. (e.g. {{url}})
]: any -> record<allIncludedPages: table<enumeratedSource: list, environmentVariables: list, evaluatedResults: list, pageLink: string, syntaxErrorMessages: list>, sourceDebugPage: record<enumeratedSource: list<string>, environmentVariables: list<string>, evaluatedResults: list<string>, pageLink: string, syntaxErrorMessages: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/esi-debugger-api/v1/debug" $qp)
  let body = {clientIP: $clientIP, clientRequestHeaders: $clientRequestHeaders, originServer: $originServer, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get error statistics
#
# POST /estats
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-estats — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-estats
export def "estats post-estats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --cpCode: int # CP code you want to get the error statistics for. You need to provide either this value or `url`. (e.g. {{cpCode}})
  --delivery: string@delivery-completer # Type of network you want to get traffic data for, either `STANDARD_TLS` or `ENHANCED_TLS`. Without this filter, Edge Diagnostics checks on its own the type of delivery used by the requested CP code or URL and returns data for it. If it uses both types, then Edge Diagnostics returns data for the type which got all data collected faster. If you choose the delivery type not used by your resource, then the results are empty. To verify the delivery type of your resource, run the [Get an edge hostname](https://techdocs.akamai.com/edge-hostnames/reference/get-edgehostnameid#getedgehostname) operation in [Edge Hostnames API](https://techdocs.akamai.com/edge-hostnames/reference/api). It is the `securityType` value. (e.g. {{delivery}})
  --errorType: string@errorType-completer # Type of traffic direction you want to get the data for, either `EDGE_ERRORS` or `ORIGIN_ERRORS`. The `EDGE_ERRORS` value returns data for the edge server response to a client and `ORIGIN_ERRORS` for the edge server forward request to an origin server. Without this filter, Edge Diagnostics returns data for both. (e.g. {{errorType}})
  --body-url: string # Fully qualified URL you want to get the error statistics for. You need to provide either this value or `cpCode`. (format: uri, e.g. {{url}})
]: any -> record<completedTime: string, createdBy: string, createdTime: string, executionStatus: string, request: record<cpCode: int, delivery: string, errorType: string, url: string>, result: record<edgeErrors: int, edgeFailurePercentage: int, edgeHits: int, edgeStatusCodeDistribution: list<record>, originErrors: int, originFailurePercentage: int, originHits: int, originStatusCodeDistribution: list<record>, topEdgeIpsWithError: list<record>, topEdgeIpsWithErrorFromOrigin: list<record>, topEdgeIpsWithSuccess: list<record>, topEdgeIpsWithSuccessFromOrigin: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/estats" $qp)
  let body = {cpCode: $cpCode, delivery: $delivery, errorType: $errorType, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Launch a GREP request
#
# POST /grep
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-grep — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-grep
# --arls shape: {comparison: "CONTAINS"|"NOT_CONTAINS", value: list}
# --httpStatusCodes shape: {comparison: "EQUALS"|"NOT_EQUALS", value: list}
export def "grep post-grep" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --arls: record # Collects ARLs to filter the logs by. — shape: {comparison: "CONTAINS"|"NOT_CONTAINS", value: list}
  --clientIps: list # Lists client IPs to filter the logs by.
  --cpCodes: list # Lists CP codes you want to get the logs for. You need to provide either this value or `hostnames`.
  edgeIp: string # Edge IP you want to get the logs for. If you don't know if an IP is the edge IP, run the [Verify an IP](https://techdocs.akamai.com/edge-diagnostics/reference/post-verify-edge-ip) operation first. You can use the edge server IP value from the `answerSection` array in the [Get domain details with dig](https://techdocs.akamai.com/edge-diagnostics/reference/post-dig) operation response or the `ip` value from the `edgeIps` array in the [collected diagnostic data](https://techdocs.akamai.com/edge-diagnostics/reference/get-user-diagnostic-data-group-records). (e.g. {{edgeIp}})
  end: string # ISO 8601 timestamp for a point of time in the past when the log search window ends. (format: date-time, e.g. {{end}})
  --hostnames: list # Lists hostnames you want to get the logs for. You need to provide either this value or `cpCodes`.
  --httpStatusCodes: record # Filters the logs by specific HTTP status codes. — shape: {comparison: "EQUALS"|"NOT_EQUALS", value: list}
  logType: string@logType-completer # Log record type you want to get. Possible values are: `R` for client requests to an edge server, `F` for forward requests from an edge server to the origin, or `BOTH`. (e.g. {{logType}})
  start: string # ISO 8601 timestamp for a point of time in the past when the log search window starts. You can get the logs from either the last 6 or 24 hours depending on the server and traffic conditions. The recommended 10-minute periods ensure that data fetches quickly and you get the most relevant logs. (format: date-time, e.g. {{start}})
  --userAgents: list # Lists user agents to filter the logs by.
]: any -> record<completedTime: string, createdBy: string, createdTime: string, edgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, errorResponse: record<detail: string, errors: list<string>, status: string, title: string, type: string>, executionStatus: string, link: string, logLinesCount: int, request: record<arls: record<comparison: string, value: list>, clientIps: list<string>, cpCodes: list<int>, edgeIp: string, end: string, hostnames: list<string>, httpStatusCodes: record<comparison: string, value: list>, logType: string, start: string, userAgents: list<string>>, requestId: int, result: record<legend: record<fObjectStatus: record, fObjectStatus2: record, fObjectStatus3: record, logType: record, rObjectStatus: record, rObjectStatus2: record, rObjectStatus3: record>, logs: list<record>>, retryAfter: int, suggestedActions: list<string>, warning: record<key: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grep" $qp)
  let body = {arls: $arls, clientIps: $clientIps, cpCodes: $cpCodes, edgeIp: $edgeIp, end: $end, hostnames: $hostnames, httpStatusCodes: $httpStatusCodes, logType: $logType, start: $start, userAgents: $userAgents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specific logs
#
# GET /grep
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-grep — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-grep
export def "grep get-grep" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --edgeIp: string # IP address that belongs to edge server and you want to get the logs for. To verify if an IP address belongs to an edge server, run the [Verify an IP](https://techdocs.akamai.com/edge-diagnostics/reference/post-verify-edge-ip) operation. To get the IP, you may need to run the [Get domain details with dig](https://techdocs.akamai.com/edge-diagnostics/reference/post-dig) or [Get diagnostic data of a group](https://techdocs.akamai.com/edge-diagnostics/reference/get-user-diagnostic-data-group-records) operation first. This is the IP value from the `answerSection` array in the [Get domain details with dig](https://techdocs.akamai.com/edge-diagnostics/reference/post-dig) operation response or the `ip` value from the `edgeIps` array in the [collected diagnostic data](https://techdocs.akamai.com/edge-diagnostics/reference/get-user-diagnostic-data-group-records). (e.g. 192.0.2.192)
  --cpCode: int # CP code you want to get the logs for. (e.g. 746478)
  --clientIp: string # Client IP to filter the logs by. (e.g. 192.0.2.95)
  --objectStatus: string # Object status codes you want to get the logs for. To see available values, check [Object status codes](https://techdocs.akamai.com/edge-diagnostics/docs/object-status). (e.g. pxR)
  --httpStatusCode: int # HTTP status code to filter the logs by. (e.g. 200)
  --userAgent: string # User agent to filter the logs by. (e.g. Mozilla/5.0)
  --arl: string # [ARL](https://techdocs.akamai.com/edge-diagnostics/docs/arl-syntax) to filter the logs by. (e.g. /=/1234/12345/1d/ts.download.akamai.com/eum/results.txt)
  --start: string # ISO 8601 timestamp for a point of time in the past when the log search window starts. You can get the logs from either the last 6 or 24 hours depending on the server and traffic conditions. The recommended 10-minute periods ensure that data fetches quickly and you get the most relevant logs. (e.g. 2022-03-15T06:08:40Z)
  --end: string # ISO 8601 timestamp for a point of time in the past when the log search window ends. (e.g. 2022-03-15T06:08:43Z)
  --logType: string@logType-completer-1 # __Enum__ Record type of the logs. Possible values are  either `R` for client requests to an edge server or `F` for forward requests from an edge server to the origin. (e.g. R)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<createdBy: string, createdTime: string, executionStatus: string, logLinesCount: int, request: record<cpCodes: list<int>, edgeIp: string, end: string, httpStatusCodes: record<comparison: string, value: list>, logType: string, objectStatus: string, start: string>, result: record<legend: record<fObjectStatus: record, fObjectStatus2: record, fObjectStatus3: record, logType: record, rObjectStatus: record, rObjectStatus2: record, rObjectStatus3: record>, logs: list<record>>, suggestedActions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "edgeIp" $edgeIp "scalar") (serialize-qp "cpCode" $cpCode "scalar") (serialize-qp "clientIp" $clientIp "scalar") (serialize-qp "objectStatus" $objectStatus "scalar") (serialize-qp "httpStatusCode" $httpStatusCode "scalar") (serialize-qp "userAgent" $userAgent "scalar") (serialize-qp "arl" $arl "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "logType" $logType "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grep" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check a GREP request status
#
# GET /grep/requests/{requestId}
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-grep-request — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-grep-request
export def "grep-requests get-grep-request" [
  requestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<completedTime: string, createdBy: string, createdTime: string, edgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, errorResponse: record<detail: string, errors: list<string>, status: string, title: string, type: string>, executionStatus: string, link: string, logLinesCount: int, request: record<arls: record<comparison: string, value: list>, clientIps: list<string>, cpCodes: list<int>, edgeIp: string, end: string, hostnames: list<string>, httpStatusCodes: record<comparison: string, value: list>, logType: string, start: string, userAgents: list<string>>, requestId: int, result: record<legend: record<fObjectStatus: record, fObjectStatus2: record, fObjectStatus3: record, logType: record, rObjectStatus: record, rObjectStatus2: record, rObjectStatus3: record>, logs: list<record>>, retryAfter: int, suggestedActions: list<string>, warning: record<key: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/grep/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List GTM properties
#
# GET /gtm/gtm-properties
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-gtm-properties — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-gtm-properties
export def "gtm-gtm-properties get-gtm-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<gtmProperties: table<domain: string, hostname: string, property: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gtm/gtm-properties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List test and target IPs for a GTM hostname
#
# GET /gtm/{property}/{domain}/gtm-property-ips
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-gtm-property-domain-gtm-property-ips — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-gtm-property-domain-gtm-property-ips
export def "gtm-gtm-property-ips get-gtm-property-domain-gtm-property-ips" [
  property: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<gtmPropertyIps: record<domain: string, property: string, targets: list<string>, testIps: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/gtm/($property)/($domain)/gtm-property-ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List IP acceleration hostnames
#
# GET /ipa/hostnames
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-ipa-hostnames — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-ipa-hostnames
export def "ipa-hostnames get-ipa-hostnames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<hostnames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipa/hostnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Locate an IP network
#
# POST /locate-ip
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-locate-ip — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-locate-ip
export def "locate-ip post-locate-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  ipAddresses: list # Up to 10 IP addresses you want to get the data for.
]: any -> record<completedTime: string, createdBy: string, createdTime: string, executionStatus: string, request: record<ipAddresses: list<string>>, results: table<executionStatus: string, geoLocation: record, ipAddress: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locate-ip" $qp)
  let body = {ipAddresses: $ipAddresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Launch a metadata tracing request
#
# POST /metadata-tracer
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-mdt — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-mdt
export def "metadata-tracer post-mdt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --edgeIp: string # IP of the edge server you want to run the operation from. If you don't know if an IP is the edge IP, run the [Verify an IP](https://techdocs.akamai.com/edge-diagnostics/reference/post-verify-edge-ip) operation. Provide either this value or `mdtLocationId`. (e.g. {{edgeIp}})
  --httpBody: string # The POST call's request body. (e.g. {{httpBody}})
  --httpMethod: string@httpMethod-completer # HTTP method you want to use to run the operation, either `HEAD`, `POST`, or the default `GET` method. (default: GET, e.g. {{httpMethod}})
  --mdtLocationId: string # Unique identifier for an available location closest to your end users. To get this value, run the [List available locations for metadata tracing](https://techdocs.akamai.com/edge-diagnostics/reference/get-mdt-locations) operation first. For `GET` and `HEAD`, provide either this value or `edgeIp`. (e.g. {{mdtLocationId}})
  --requestHeaders: list # Customized headers for metadata tracer request in the format `header: value`. Check [Pragma headers](https://techdocs.akamai.com/edge-diagnostics/docs/pragma-headers) for the list of Akamized Pragma headers you can use here.
  --sensitiveRequestHeaderKeys: list # Sensitive `requestHeaders` you don't want to store in the database after running the request. Check [Sensitive headers](https://techdocs.akamai.com/edge-diagnostics/reference/sensitive-headers) to see the list of request headers treated as sensitive by default.
  --body-url: string # URL configured in Property Manager you want to get the metadata trace for. (format: uri, e.g. {{url}})
  --useStaging: oneof<nothing, bool> # Runs the request on the staging environment, `false` by default.  (e.g. {{useStaging}})
]: any -> record<completedTime: string, createdBy: string, createdTime: string, edgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, executionStatus: string, internalIp: string, link: string, request: record<edgeIp: string, httpBody: string, httpMethod: string, mdtLocationId: string, requestHeaders: list<string>, sensitiveRequestHeaderKeys: list<string>, url: string, useStaging: bool>, requestId: int, result: record<arlDataXml: string, exitCode: int, httpStatusCode: int, httpVersion: string, reasonPhrase: string, responseHeaderList: list<string>, traceInformation: list<record>>, retryAfter: int, summary: record<accountId: string, assetId: string, contractId: string, groupId: string, propertyId: string, propertyName: string, propertyVersion: int, ruleFormat: string, rules: record<options: record, behaviors: list, children: list, comments: string, criteria: list, criteriaMustSatisfy: string, name: string, uuid: string, variables: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata-tracer" $qp)
  let body = {edgeIp: $edgeIp, httpBody: $httpBody, httpMethod: $httpMethod, mdtLocationId: $mdtLocationId, requestHeaders: $requestHeaders, sensitiveRequestHeaderKeys: $sensitiveRequestHeaderKeys, url: $body_url, useStaging: $useStaging} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List available edge server locations for metadata tracing
#
# GET /metadata-tracer/locations
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-mdt-locations — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-mdt-locations
export def "metadata-tracer-locations get-mdt-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<mdtLocations: table<id: string, supportedMethods: list, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata-tracer/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check a metadata tracing request status
#
# GET /metadata-tracer/requests/{requestId}
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-mdt-request — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-mdt-request
export def "metadata-tracer-requests get-mdt-request" [
  requestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<completedTime: string, createdBy: string, createdTime: string, edgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, executionStatus: string, internalIp: string, link: string, request: record<edgeIp: string, httpBody: string, httpMethod: string, mdtLocationId: string, requestHeaders: list<string>, sensitiveRequestHeaderKeys: list<string>, url: string, useStaging: bool>, requestId: int, result: record<arlDataXml: string, exitCode: int, httpStatusCode: int, httpVersion: string, reasonPhrase: string, responseHeaderList: list<string>, traceInformation: list<record>>, retryAfter: int, summary: record<accountId: string, assetId: string, contractId: string, groupId: string, propertyId: string, propertyName: string, propertyVersion: int, ruleFormat: string, rules: record<options: record, behaviors: list, children: list, comments: string, criteria: list, criteriaMustSatisfy: string, name: string, uuid: string, variables: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/metadata-tracer/requests/($requestId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test network connectivity with MTR
#
# POST /mtr
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-mtr — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-mtr
export def "mtr post-mtr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  destination: string # MTR destination compliant with the `destinationType`, either a hostname or a destination IP. To build an object for a GTM hostname, enter the `target` value returned by the [List test and target IPs for a GTM hostname](https://techdocs.akamai.com/edge-diagnostics/reference/get-gtm-property-domain-gtm-property-ips) operation. For a Site Shield hostname, enter a destination IP address. (e.g. {{destination}})
  destinationType: string@destinationType-completer # Type of destination input, either `IP` or `HOST`. To build an object for a GTM or Site Shield hostname, choose `IP`. (e.g. {{destinationType}})
  packetType: string@packetType-completer # Packet type used by MTR, either `ICMP` or `TCP`. (e.g. {{packetType}})
  --port: int@port-completer # Port to use to run MTR, either `80` or `443`. Provide it only for `destinationType` set to `HOST`. (e.g. {{port}})
  --resolveDns: oneof<nothing, bool> # Resolves DNS for each hop. (e.g. {{resolveDns}})
  --showIps: oneof<nothing, bool> # Shows IPs for each hop. (e.g. {{showIps}})
  --showLocations: oneof<nothing, bool> # Shows locations for each hop. (e.g. {{showLocations}})
  --siteShieldHostname: string # Site Shield hostname you want to run the MTR for. (format: hostname, e.g. {{siteShieldHostname}})
  --body-source: string # MTR source compliant with the `sourceType`, either an edge server IP or a location. For locations, enter `edgeLocationId` for an edge server location closest to your end users. To get this value, run the [List available edge server locations](https://techdocs.akamai.com/edge-diagnostics/reference/get-edge-locations) operation first. For edge IPs, use the edge server IP value from the `answerSection` array in the [Get domain details with dig](https://techdocs.akamai.com/edge-diagnostics/reference/post-dig) operation response. To build an object for a GTM hostname, enter the `testIp` value returned by the [List test and target IPs for a GTM hostname](https://techdocs.akamai.com/edge-diagnostics/reference/get-gtm-property-domain-gtm-property-ips) operation. (e.g. {{source}})
  --sourceType: string@sourceType-completer # Type of the source input, either `EDGE_IP` or `LOCATION`. To build an object for a GTM hostname, choose `EDGE_IP`. (e.g. {{sourceType}})
]: any -> record<completedTime: string, createdBy: string, createdTime: string, destinationInternalIp: string, destinationIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, executionStatus: string, request: record<destination: string, destinationType: string, packetType: string, port: int, resolveDns: bool, showIps: bool, showLocations: bool, siteShieldHostname: string, source: string, sourceType: string>, result: record<averageLatency: float, hops: list<record>, host: string, packetLoss: float, result: string, startTime: int>, siteShieldIp: string, siteShieldIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, sourceInternalIp: string, sourceIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mtr" $qp)
  let body = {destination: $destination, destinationType: $destinationType, packetType: $packetType, port: $port, resolveDns: $resolveDns, showIps: $showIps, showLocations: $showLocations, siteShieldHostname: $siteShieldHostname, source: $body_source, sourceType: $sourceType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Translate an Akamaized URL
#
# POST /translated-url
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-translated-url — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-translated-url
export def "translated-url post-translated-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --body-url: string # Fully qualified [Akamaized URL](https://techdocs.akamai.com/edge-diagnostics/docs/arl-syntax) you want to get the details for. (e.g. {{url}})
]: any -> record<request: record<url: string>, translatedUrl: record<cacheControl: string, cacheKeyHostname: string, cpCode: int, pragma: string, serialNumber: string, ttl: string, typeCode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/translated-url" $qp)
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run the URL health check
#
# POST /url-health-check
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-url-health-check — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-url-health-check
export def "url-health-check post-url-health-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --edgeLocationId: string # Unique identifier for an edge server location closest to your end users. Run the [List available edge server locations](https://techdocs.akamai.com/edge-diagnostics/reference/get-edge-locations) operation to get this value. (e.g. {{edgeLocationId}})
  --ipVersion: string@ipVersion-completer # IP version for the URL health check to use to run cURL and MTR, either `IPV4` or `IPV6`. (e.g. {{ipVersion}})
  --packetType: string@packetType-completer # Packet type for the URL health check to use to run MTR, either `ICMP` or `TCP`. Provide it only for requests with `CONNECTIVITY` in the `viewsAllowed` array. (e.g. {{packetType}})
  --port: int@port-completer # Port number for the URL health check to use to run MTR, either `80` or `443`. Provide it only for requests with `CONNECTIVITY` in the `viewsAllowed` array. (e.g. {{port}})
  --queryType: string@queryType-completer # DNS query type you want to get the records of with the DIG command. Possible values are: `A`, `AAAA`, `SOA`, `CNAME`, `PTR`, `MX`, `NS`, `TXT`, `SRV`, `CAA`, and `ANY`. To learn more about them, check [Supported DNS record types](https://techdocs.akamai.com/edge-diagnostics/docs/domain-details-dig#supported-dns-record-types). (e.g. {{queryType}})
  --requestHeaders: list # Customized headers for the `curl` request in the format `header: value`. The request includes [Akamai Pragma headers](https://techdocs.akamai.com/edge-diagnostics/docs/pragma-headers) by default.
  --runFromSiteShield: oneof<nothing, bool> # Runs a URL health check from a Site Shield map. To learn more, check [Site Shield requests](https://techdocs.akamai.com/edge-diagnostics/reference/site-shield-requests). (e.g. {{runFromSiteShield}})
  --sensitiveRequestHeaderKeys: list # Sensitive `requestHeaders` you don't want to store in the database after running the request. Check [Sensitive headers](https://techdocs.akamai.com/edge-diagnostics/reference/sensitive-headers) to see the list of request headers treated as sensitive by default.
  --spoofEdgeIp: string # IP of the edge server you want to serve traffic from. You can use the edge server IP value from the `answerSection` array in the [Get domain details with dig](https://techdocs.akamai.com/edge-diagnostics/reference/post-dig) operation response. (e.g. {{spoofEdgeIp}})
  --body-url: string # URL you want to run the health check for. (e.g. {{url}})
  --viewsAllowed: list # Additional operations for the URL health check to run. `CONNECTIVITY` runs the [Test network connectivity with MTR](https://techdocs.akamai.com/edge-diagnostics/reference/post-mtr) operation and `LOGS` runs the [Get specific logs](https://techdocs.akamai.com/edge-diagnostics/reference/get-grep) operation.
]: any -> record<connectivity: table<additionalRequestParameters: record, destinationContext: string, destinationIpLocation: record, errorResponse: record, executionContext: string, executionStatus: string, info: record, result: record, sourceContext: string, sourceIpLocation: record, suggestedActions: list>, content: table<additionalRequestParameters: record, errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, createdBy: string, createdTime: string, domainDetails: table<additionalRequestParameters: record, errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, errorResponse: record<detail: string, errors: list<string>, status: string, title: string, type: string>, executionStatus: string, internalIp: string, internalIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, link: string, logLines: table<errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, request: record<edgeLocationId: string, ipVersion: string, packetType: string, port: int, queryType: string, requestHeaders: list<string>, runFromSiteShield: bool, sensitiveRequestHeaderKeys: list<string>, spoofEdgeIp: string, url: string, viewsAllowed: list<string>>, requestId: int, retryAfter: int, siteShieldIp: string, siteShieldIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, spoofEdgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, summary: record<cacheKeyHostname: string, cacheSetting: string, connectivity: list<record>, content: list<record>, cpCode: int, domainDetails: list<record>, edgeServerIp: string, edgeStatusCode: string, errorMessage: string, logLines: list<record>, originResponseCode: string, originServerHostname: string, originServerIp: string, serialNumber: string, ttl: string, typeCode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/url-health-check" $qp)
  let body = {edgeLocationId: $edgeLocationId, ipVersion: $ipVersion, packetType: $packetType, port: $port, queryType: $queryType, requestHeaders: $requestHeaders, runFromSiteShield: $runFromSiteShield, sensitiveRequestHeaderKeys: $sensitiveRequestHeaderKeys, spoofEdgeIp: $spoofEdgeIp, url: $body_url, viewsAllowed: $viewsAllowed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a URL health check response
#
# GET /url-health-check/requests/{requestId}
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-url-health-check-requests — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-url-health-check-requests
export def "url-health-check-requests get-url-health-check-requests" [
  requestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeContentResponseBody: oneof<nothing, bool> # Includes response bodies in the response. (e.g. false)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<connectivity: table<additionalRequestParameters: record, destinationContext: string, destinationIpLocation: record, errorResponse: record, executionContext: string, executionStatus: string, info: record, result: record, sourceContext: string, sourceIpLocation: record, suggestedActions: list>, content: table<additionalRequestParameters: record, errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, createdBy: string, createdTime: string, domainDetails: table<additionalRequestParameters: record, errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, errorResponse: record<detail: string, errors: list<string>, status: string, title: string, type: string>, executionStatus: string, internalIp: string, internalIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, link: string, logLines: table<errorResponse: record, executionContext: string, executionStatus: string, result: record, suggestedActions: list>, request: record<edgeLocationId: string, ipVersion: string, packetType: string, port: int, queryType: string, requestHeaders: list<string>, runFromSiteShield: bool, sensitiveRequestHeaderKeys: list<string>, spoofEdgeIp: string, url: string, viewsAllowed: list<string>>, requestId: int, retryAfter: int, siteShieldIp: string, siteShieldIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, spoofEdgeIpLocation: record<asNumber: int, city: string, countryCode: string, regionCode: string>, summary: record<cacheKeyHostname: string, cacheSetting: string, connectivity: list<record>, content: list<record>, cpCode: int, domainDetails: list<record>, edgeServerIp: string, edgeStatusCode: string, errorMessage: string, logLines: list<record>, originResponseCode: string, originServerHostname: string, originServerIp: string, serialNumber: string, ttl: string, typeCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeContentResponseBody" $includeContentResponseBody "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/url-health-check/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a diagnostic link
#
# POST /user-diagnostic-data/groups
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-user-diagnostic-data-groups — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-user-diagnostic-data-groups
export def "user-diagnostic-data-groups post-user-diagnostic-data-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --ipaHostname: string # IP acceleration hostname you want to collect the diagnostic data for. You need to provide either this value or `url`. To get the available hostnames, run the [List IP acceleration hostnames](https://techdocs.akamai.com/edge-diagnostics/reference/get-ipa-hostnames) operation. (format: hostname, e.g. {{ipaHostname}})
  --note: string # Notes about the group or issues experienced by group's end users.  (e.g. {{note}})
  --body-url: string # URL you want to collect the diagnostic data for. You need to provide either this value or `ipaHostname`. (format: uri, e.g. {{url}})
]: any -> record<createdBy: string, createdTime: string, diagnosticLink: string, diagnosticLinkStatus: string, groupId: string, ipaHostname: string, note: string, recordCount: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user-diagnostic-data/groups" $qp)
  let body = {ipaHostname: $ipaHostname, note: $note, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List end user groups
#
# GET /user-diagnostic-data/groups
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-user-diagnostic-data-groups — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-user-diagnostic-data-groups
export def "user-diagnostic-data-groups get-user-diagnostic-data-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<groups: table<createdBy: string, createdTime: string, diagnosticLink: string, diagnosticLinkStatus: string, groupId: string, ipaHostname: string, note: string, recordCount: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user-diagnostic-data/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get diagnostic data for an end user group
#
# GET /user-diagnostic-data/groups/{groupId}/records
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/get-user-diagnostic-data-group-records — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: get-user-diagnostic-data-group-records
export def "user-diagnostic-data-groups-records get-user-diagnostic-data-group-records" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeCurl: oneof<nothing, bool> # Includes `curl` results in the response. (e.g. true)
  --includeDig: oneof<nothing, bool> # Includes `dig` results in the response. (e.g. true)
  --includeMtr: oneof<nothing, bool> # Includes MTR results in the response. (e.g. true)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<createdBy: string, createdTime: string, diagnosticLink: string, diagnosticLinkStatus: string, expiryTime: string, groupId: string, ipaHostname: string, note: string, records: table<cipher: string, clientDnsIpv4: record, clientDnsIpv6: record, clientIpv4: record, clientIpv6: record, cookie: bool, createdEpoch: int, createdTime: string, curlResults: list, digResults: list, edgeIps: list, mtrResults: list, preferredClientIp: record, protocol: string, uniqueId: int, userAgent: string>, submissionsRemaining: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCurl" $includeCurl "scalar") (serialize-qp "includeDig" $includeDig "scalar") (serialize-qp "includeMtr" $includeMtr "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user-diagnostic-data/groups/($groupId)/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify an IP
#
# POST /verify-edge-ip
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-verify-edge-ip — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-verify-edge-ip
export def "verify-edge-ip post-verify-edge-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  ipAddresses: list # Up to 10 IP addresses you want to get the data for.
]: any -> record<completedTime: string, createdBy: string, createdTime: string, executionStatus: string, request: record<ipAddresses: list<string>>, results: table<executionStatus: string, ipAddress: string, isEdgeIp: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verify-edge-ip" $qp)
  let body = {ipAddresses: $ipAddresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify and locate an IP
#
# POST /verify-locate-ip
# Docs: https://techdocs.akamai.com/edge-diagnostics/reference/post-verify-locate-ip — See documentation for this operation in Akamai's Edge Diagnostics API
# operationId: post-verify-locate-ip
export def "verify-locate-ip post-verify-locate-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  ipAddress: string # IP address you want to get the data for. (e.g. {{ipAddress}})
]: any -> record<createdBy: string, createdTime: string, executionStatus: string, request: record<ipAddress: string>, result: record<geoLocation: record<areaCode: string, asNumber: int, city: string, continent: string, countryCode: string, county: string, dma: int, fips: string, latitude: float, longitude: float, msa: int, network: string, networkType: string, pmsa: int, proxy: string, regionCode: string, throughput: string, timeZone: string, zipCode: string>, isEdgeIp: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verify-locate-ip" $qp)
  let body = {ipAddress: $ipAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
