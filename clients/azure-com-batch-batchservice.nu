# Auto-generated client for BatchService v2019-08-01.10.0
# Source: https://api.apis.guru/v2/specs/azure.com/batch-BatchService/2019-08-01.10.0/swagger.json
# Auth: --token flag or $env.BATCHSERVICE_TOKEN

const BASE_URL = "{batchUrl}"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BATCHSERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["{batchUrl}"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def certificate-format-completer [] { ["cer" "pfx"] }
def on-all-tasks-complete-completer [] { ["noaction" "terminatejob"] }
def on-task-failure-completer [] { ["noaction" "performexitoptionsjobaction"] }
def disable-tasks-completer [] { ["requeue" "terminate" "wait"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }
def node-disable-scheduling-option-completer [] { ["requeue" "taskcompletion" "terminate"] }
def node-reboot-option-completer [] { ["requeue" "retaineddata" "taskcompletion" "terminate"] }
def node-reimage-option-completer [] { ["requeue" "retaineddata" "taskcompletion" "terminate"] }
def node-deallocation-option-completer [] { ["requeue" "retaineddata" "taskcompletion" "terminate"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applications list" } } | get name | first)
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

# Lists all of the applications available in the specified Account.
#
# GET /applications
# operationId: Application_List
export def "applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 applications can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<displayName: string, id: string, versions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets information about the specified Application.
#
# GET /applications/{applicationId}
# operationId: Application_Get
export def "applications get" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<displayName: string, id: string, versions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/applications/{application_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Lists all of the Certificates that have been added to the specified Account.
#
# GET /certificates
# operationId: Certificate_List
export def "certificates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-certificates.
  --select: string # An OData $select clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Certificates can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<deleteCertificateError: record, previousState: string, previousStateTransitionTime: string, publicData: string, state: string, stateTransitionTime: string, thumbprint: string, thumbprintAlgorithm: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "$select": $select, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Adds a Certificate to the specified Account.
#
# POST /certificates
# operationId: Certificate_Add
export def "certificates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --certificate-format: string@certificate-format-completer
  data: string
  --password: string # This is required if the Certificate format is pfx. It should be omitted if the Certificate format is cer.
  thumbprint: string
  thumbprint_algorithm: string
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates" $qp)
  let req_body = {"certificateFormat": $certificate_format, "data": $data, "password": $password, "thumbprint": $thumbprint, "thumbprintAlgorithm": $thumbprint_algorithm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Deletes a Certificate from the specified Account.
#
# DELETE /certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})
# operationId: Certificate_Delete
export def "certificates delete" [
  thumbprint_algorithm: string
  thumbprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($thumbprint_algorithm | is-empty) { error make --unspanned { msg: "path parameter 'thumbprintAlgorithm' must be non-empty" } }
  if ($thumbprint | is-empty) { error make --unspanned { msg: "path parameter 'thumbprint' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({thumbprint_algorithm: (encode-path-segment $thumbprint_algorithm), thumbprint: (encode-path-segment $thumbprint)} | format pattern "/certificates(thumbprintAlgorithm={thumbprint_algorithm},thumbprint={thumbprint})") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets information about the specified Certificate.
#
# GET /certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})
# operationId: Certificate_Get
export def "certificates get" [
  thumbprint_algorithm: string
  thumbprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<deleteCertificateError: record<code: string, message: string, values: list<record>>, previousState: string, previousStateTransitionTime: string, publicData: string, state: string, stateTransitionTime: string, thumbprint: string, thumbprintAlgorithm: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($thumbprint_algorithm | is-empty) { error make --unspanned { msg: "path parameter 'thumbprintAlgorithm' must be non-empty" } }
  if ($thumbprint | is-empty) { error make --unspanned { msg: "path parameter 'thumbprint' must be non-empty" } }
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({thumbprint_algorithm: (encode-path-segment $thumbprint_algorithm), thumbprint: (encode-path-segment $thumbprint)} | format pattern "/certificates(thumbprintAlgorithm={thumbprint_algorithm},thumbprint={thumbprint})") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Cancels a failed deletion of a Certificate from the specified Account.
#
# POST /certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})/canceldelete
# operationId: Certificate_CancelDeletion
export def "certificates-canceldelete cancel-deletion" [
  thumbprint_algorithm: string
  thumbprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($thumbprint_algorithm | is-empty) { error make --unspanned { msg: "path parameter 'thumbprintAlgorithm' must be non-empty" } }
  if ($thumbprint | is-empty) { error make --unspanned { msg: "path parameter 'thumbprint' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({thumbprint_algorithm: (encode-path-segment $thumbprint_algorithm), thumbprint: (encode-path-segment $thumbprint)} | format pattern "/certificates(thumbprintAlgorithm={thumbprint_algorithm},thumbprint={thumbprint})/canceldelete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Lists all of the Jobs in the specified Account.
#
# GET /jobs
# operationId: Job_List
export def "jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-jobs.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Jobs can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<commonEnvironmentSettings: list, constraints: record, creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobManagerTask: record, jobPreparationTask: record, jobReleaseTask: record, lastModified: string, metadata: list, networkConfiguration: record, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record, url: string, usesTaskDependencies: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "$select": $select, "$expand": $expand, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Adds a Job to the specified Account.
#
# POST /jobs
# operationId: Job_Add
# --commonEnvironmentSettings item shape: {name: string, value?: string}
# --constraints shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
# --jobManagerTask shape: {allowLowPriorityNode?: bool, applicationPackageReferences?: list, authenticationTokenSettings?: any, commandLine: string, constraints?: any, containerSettings?: any, displayName?: string, environmentSettings?: list, id: string, killJobOnCompletion?: bool, outputFiles?: list, resourceFiles?: list, runExclusive?: bool, userIdentity?: any}
# --jobPreparationTask shape: {commandLine: string, constraints?: any, containerSettings?: any, environmentSettings?: list, id?: string, rerunOnNodeRebootAfterSuccess?: bool, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
# --jobReleaseTask shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, id?: string, maxWallClockTime?: string, resourceFiles?: list, retentionTime?: string, userIdentity?: any}
# --metadata item shape: {name: string, value: string}
# --networkConfiguration shape: {subnetId: string}
# --poolInfo shape: {autoPoolSpecification?: any, poolId?: string}
export def "jobs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --common-environment-settings: list # Individual Tasks can override an environment setting specified here by specifying the same setting name with a different value. — item shape: {name: string, value?: string}
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
  --display-name: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two IDs within an Account that differ only by case).
  --job-manager-task: any # The Job Manager Task is automatically started when the Job is created. The Batch service tries to schedule the Job Manager Task before any other Tasks in the Job. When shrinking a Pool, the Batch service tries to preserve Nodes where Job Manager Tasks are running for as long as possible (that is, Compute Nodes running 'normal' Tasks are removed before Compute Nodes running Job Manager Tasks). When a Job Manager Task fails and needs to be restarted, the system tries to schedule it at the highest priority. If there are no idle Compute Nodes available, the system may terminate one of the running Tasks in the Pool and return it to the queue in order to make room for the Job Manager Task to restart. Note that a Job Manager Task in one Job does not have priority over Tasks in other Jobs. Across Jobs, only Job level priorities are observed. For example, if a Job Manager in a priority 0 Job needs to be restarted, it will not displace Tasks of a priority 1 Job. Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. — shape: {allowLowPriorityNode?: bool, applicationPackageReferences?: list, authenticationTokenSettings?: any, commandLine: string, constraints?: any, containerSettings?: any, displayName?: string, environmentSettings?: list, id: string, killJobOnCompletion?: bool, outputFiles?: list, resourceFiles?: list, runExclusive?: bool, userIdentity?: any}
  --job-preparation-task: any # You can use Job Preparation to prepare a Node to run Tasks for the Job. Activities commonly performed in Job Preparation include: Downloading common resource files used by all the Tasks in the Job. The Job Preparation Task can download these common resource files to the shared location on the Node. (AZ_BATCH_NODE_ROOT_DIR\shared), or starting a local service on the Node so that all Tasks of that Job can communicate with it. If the Job Preparation Task fails (that is, exhausts its retry count before exiting with exit code 0), Batch will not run Tasks of this Job on the Node. The Compute Node remains ineligible to run Tasks of this Job until it is reimaged. The Compute Node remains active and can be used for other Jobs. The Job Preparation Task can run multiple times on the same Node. Therefore, you should write the Job Preparation Task to handle re-execution. If the Node is rebooted, the Job Preparation Task is run again on the Compute Node before scheduling any other Task of the Job, if rerunOnNodeRebootAfterSuccess is true or if the Job Preparation Task did not previously complete. If the Node is reimaged, the Job Preparation Task is run again before scheduling any Task of the Job. Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. — shape: {commandLine: string, constraints?: any, containerSettings?: any, environmentSettings?: list, id?: string, rerunOnNodeRebootAfterSuccess?: bool, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
  --job-release-task: any # The Job Release Task runs when the Job ends, because of one of the following: The user calls the Terminate Job API, or the Delete Job API while the Job is still active, the Job's maximum wall clock time constraint is reached, and the Job is still active, or the Job's Job Manager Task completed, and the Job is configured to terminate when the Job Manager completes. The Job Release Task runs on each Node where Tasks of the Job have run and the Job Preparation Task ran and completed. If you reimage a Node after it has run the Job Preparation Task, and the Job ends without any further Tasks of the Job running on that Node (and hence the Job Preparation Task does not re-run), then the Job Release Task does not run on that Compute Node. If a Node reboots while the Job Release Task is still running, the Job Release Task runs again when the Compute Node starts up. The Job is not marked as complete until all Job Release Tasks have completed. The Job Release Task runs in the background. It does not occupy a scheduling slot; that is, it does not count towards the maxTasksPerNode limit specified on the Pool. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, id?: string, maxWallClockTime?: string, resourceFiles?: list, retentionTime?: string, userIdentity?: any}
  --metadata: list # The Batch service does not assign any meaning to metadata; it is solely for the use of user code. — item shape: {name: string, value: string}
  --network-configuration: any # shape: {subnetId: string}
  --on-all-tasks-complete: string@on-all-tasks-complete-completer
  --on-task-failure: string@on-task-failure-completer # A Task is considered to have failed if has a failureInfo. A failureInfo is set if the Task completes with a non-zero exit code after exhausting its retry count, or if there was an error starting the Task, for example due to a resource file download error. The default is noaction.
  pool_info: any # shape: {autoPoolSpecification?: any, poolId?: string}
  --priority: int # Priority values can range from -1000 to 1000, with -1000 being the lowest priority and 1000 being the highest priority. The default value is 0. (format: int32)
  --uses-task-dependencies: oneof<nothing, bool>
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobs" $qp)
  let req_body = {"commonEnvironmentSettings": $common_environment_settings, "constraints": $constraints, "displayName": $display_name, "id": $id, "jobManagerTask": $job_manager_task, "jobPreparationTask": $job_preparation_task, "jobReleaseTask": $job_release_task, "metadata": $metadata, "networkConfiguration": $network_configuration, "onAllTasksComplete": $on_all_tasks_complete, "onTaskFailure": $on_task_failure, "poolInfo": $pool_info, "priority": $priority, "usesTaskDependencies": $uses_task_dependencies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Deletes a Job.
#
# DELETE /jobs/{jobId}
# operationId: Job_Delete
export def "jobs delete" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets information about the specified Job.
#
# GET /jobs/{jobId}
# operationId: Job_Get
export def "jobs get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<commonEnvironmentSettings: table<name: string, value: string>, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string>, creationTime: string, displayName: string, eTag: string, executionInfo: record<endTime: string, poolId: string, schedulingError: record<category: string, code: string, details: list, message: string>, startTime: string, terminateReason: string>, id: string, jobManagerTask: record<allowLowPriorityNode: bool, applicationPackageReferences: list<record>, authenticationTokenSettings: record<access: list>, commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, displayName: string, environmentSettings: list<record>, id: string, killJobOnCompletion: bool, outputFiles: list<record>, resourceFiles: list<record>, runExclusive: bool, userIdentity: record<autoUser: record, username: string>>, jobPreparationTask: record<commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, id: string, rerunOnNodeRebootAfterSuccess: bool, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, jobReleaseTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, id: string, maxWallClockTime: string, resourceFiles: list<record>, retentionTime: string, userIdentity: record<autoUser: record, username: string>>, lastModified: string, metadata: table<name: string, value: string>, networkConfiguration: record<subnetId: string>, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record<autoPoolSpecification: record<autoPoolIdPrefix: string, keepAlive: bool, pool: record, poolLifetimeOption: string>, poolId: string>, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string, usesTaskDependencies: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "$expand": $expand, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Updates the properties of the specified Job.
#
# PATCH /jobs/{jobId}
# operationId: Job_Patch
# --constraints shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
# --metadata item shape: {name: string, value: string}
# --poolInfo shape: {autoPoolSpecification?: any, poolId?: string}
export def "jobs update-by-job-id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
  --metadata: list # If omitted, the existing Job metadata is left unchanged. — item shape: {name: string, value: string}
  --on-all-tasks-complete: string@on-all-tasks-complete-completer
  --pool-info: any # shape: {autoPoolSpecification?: any, poolId?: string}
  --priority: int # Priority values can range from -1000 to 1000, with -1000 being the lowest priority and 1000 being the highest priority. If omitted, the priority of the Job is left unchanged. (format: int32)
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}") $qp)
  let req_body = {"constraints": $constraints, "metadata": $metadata, "onAllTasksComplete": $on_all_tasks_complete, "poolInfo": $pool_info, "priority": $priority} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Updates the properties of the specified Job.
#
# PUT /jobs/{jobId}
# operationId: Job_Update
# --constraints shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
# --metadata item shape: {name: string, value: string}
# --poolInfo shape: {autoPoolSpecification?: any, poolId?: string}
export def "jobs update-by-job-id-1" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
  --metadata: list # If omitted, it takes the default value of an empty list; in effect, any existing metadata is deleted. — item shape: {name: string, value: string}
  --on-all-tasks-complete: string@on-all-tasks-complete-completer
  pool_info: any # shape: {autoPoolSpecification?: any, poolId?: string}
  --priority: int # Priority values can range from -1000 to 1000, with -1000 being the lowest priority and 1000 being the highest priority. If omitted, it is set to the default value 0. (format: int32)
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}") $qp)
  let req_body = {"constraints": $constraints, "metadata": $metadata, "onAllTasksComplete": $on_all_tasks_complete, "poolInfo": $pool_info, "priority": $priority} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Adds a collection of Tasks to the specified Job.
#
# POST /jobs/{jobId}/addtaskcollection
# operationId: Task_AddCollection
# --value item shape: {affinityInfo?: any, applicationPackageReferences?: list, authenticationTokenSettings?: any, commandLine: string, constraints?: any, containerSettings?: any, dependsOn?: any, displayName?: string, environmentSettings?: list, exitConditions?: any, id: string, multiInstanceSettings?: any, outputFiles?: list, resourceFiles?: list, userIdentity?: any}
export def "jobs-addtaskcollection create-task-collection" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  value: list # The total serialized size of this collection must be less than 1MB. If it is greater than 1MB (for example if each Task has 100's of resource files or environment variables), the request will fail with code 'RequestBodyTooLarge' and should be retried again with fewer Tasks. — item shape: {affinityInfo?: any, applicationPackageReferences?: list, authenticationTokenSettings?: any, commandLine: string, constraints?: any, containerSettings?: any, dependsOn?: any, displayName?: string, environmentSettings?: list, exitConditions?: any, id: string, multiInstanceSettings?: any, outputFiles?: list, resourceFiles?: list, userIdentity?: any}
]: any -> record<value: table<eTag: string, error: record, lastModified: string, location: string, status: string, taskId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/addtaskcollection") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Disables the specified Job, preventing new Tasks from running.
#
# POST /jobs/{jobId}/disable
# operationId: Job_Disable
export def "jobs-disable disable" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  disable_tasks: string@disable-tasks-completer
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/disable") $qp)
  let req_body = {"disableTasks": $disable_tasks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Enables the specified Job, allowing new Tasks to run.
#
# POST /jobs/{jobId}/enable
# operationId: Job_Enable
export def "jobs-enable enable" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/enable") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Lists the execution status of the Job Preparation and Job Release Task for the specified Job across the Compute Nodes where the Job has run.
#
# GET /jobs/{jobId}/jobpreparationandreleasetaskstatus
# operationId: Job_ListPreparationAndReleaseTaskStatus
export def "jobs-jobpreparationandreleasetaskstatus list-preparation-and-release-task-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-job-preparation-and-release-status.
  --select: string # An OData $select clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Tasks can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<jobPreparationTaskExecutionInfo: record, jobReleaseTaskExecutionInfo: record, nodeId: string, nodeUrl: string, poolId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/jobpreparationandreleasetaskstatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "$select": $select, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets the Task counts for the specified Job.
#
# GET /jobs/{jobId}/taskcounts
# operationId: Job_GetTaskCounts
export def "jobs-taskcounts get-task-counts" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<active: int, completed: int, failed: int, running: int, succeeded: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/taskcounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Lists all of the Tasks that are associated with the specified Job.
#
# GET /jobs/{jobId}/tasks
# operationId: Task_List
export def "jobs-tasks list" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-tasks.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Tasks can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<affinityInfo: record, applicationPackageReferences: list, authenticationTokenSettings: record, commandLine: string, constraints: record, containerSettings: record, creationTime: string, dependsOn: record, displayName: string, eTag: string, environmentSettings: list, executionInfo: record, exitConditions: record, id: string, lastModified: string, multiInstanceSettings: record, nodeInfo: record, outputFiles: list, previousState: string, previousStateTransitionTime: string, resourceFiles: list, state: string, stateTransitionTime: string, stats: record, url: string, userIdentity: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/tasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "$select": $select, "$expand": $expand, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Adds a Task to the specified Job.
#
# POST /jobs/{jobId}/tasks
# operationId: Task_Add
# --affinityInfo shape: {affinityId: string}
# --applicationPackageReferences item shape: {applicationId: string, version?: string}
# --authenticationTokenSettings shape: {access?: list<string>}
# --constraints shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
# --containerSettings shape: {containerRunOptions?: string, imageName: string, registry?: any, workingDirectory?: "taskWorkingDirectory"|"containerImageDefault"}
# --dependsOn shape: {taskIdRanges?: list, taskIds?: list<string>}
# --environmentSettings item shape: {name: string, value?: string}
# --exitConditions shape: {default?: any, exitCodeRanges?: list, exitCodes?: list, fileUploadError?: any, preProcessingError?: any}
# --multiInstanceSettings shape: {commonResourceFiles?: list, coordinationCommandLine: string, numberOfInstances?: int}
# --outputFiles item shape: {destination: any, filePattern: string, uploadOptions: any}
# --resourceFiles item shape: {autoStorageContainerName?: string, blobPrefix?: string, fileMode?: string, filePath?: string, httpUrl?: string, storageContainerUrl?: string}
# --userIdentity shape: {autoUser?: any, username?: string}
export def "jobs-tasks create" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --affinity-info: any # shape: {affinityId: string}
  --application-package-references: list # Application packages are downloaded and deployed to a shared directory, not the Task working directory. Therefore, if a referenced package is already on the Node, and is up to date, then it is not re-downloaded; the existing copy on the Compute Node is used. If a referenced Package cannot be installed, for example because the package has been deleted or because download failed, the Task fails. — item shape: {applicationId: string, version?: string}
  --authentication-token-settings: any # shape: {access?: list<string>}
  command_line: string # For multi-instance Tasks, the command line is executed as the primary Task, after the primary Task and all subtasks have finished executing the coordination command line. The command line does not run under a shell, and therefore cannot take advantage of shell features such as environment variable expansion. If you want to take advantage of such features, you should invoke the shell in the command line, for example using "cmd /c MyCommand" in Windows or "/bin/sh -c MyCommand" in Linux. If the command line refers to file paths, it should use a relative path (relative to the Task working directory), or use the Batch provided environment variable (https://docs.microsoft.com/en-us/azure/batch/batch-compute-node-environment-variables).
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
  --container-settings: any # shape: {containerRunOptions?: string, imageName: string, registry?: any, workingDirectory?: "taskWorkingDirectory"|"containerImageDefault"}
  --depends-on: any # shape: {taskIdRanges?: list, taskIds?: list<string>}
  --display-name: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  --environment-settings: list # item shape: {name: string, value?: string}
  --exit-conditions: any # shape: {default?: any, exitCodeRanges?: list, exitCodes?: list, fileUploadError?: any, preProcessingError?: any}
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two IDs within a Job that differ only by case).
  --multi-instance-settings: any # Multi-instance Tasks are commonly used to support MPI Tasks. In the MPI case, if any of the subtasks fail (for example due to exiting with a non-zero exit code) the entire multi-instance Task fails. The multi-instance Task is then terminated and retried, up to its retry limit. — shape: {commonResourceFiles?: list, coordinationCommandLine: string, numberOfInstances?: int}
  --output-files: list # For multi-instance Tasks, the files will only be uploaded from the Compute Node on which the primary Task is executed. — item shape: {destination: any, filePattern: string, uploadOptions: any}
  --resource-files: list # For multi-instance Tasks, the resource files will only be downloaded to the Compute Node on which the primary Task is executed. There is a maximum size for the list of resource files. When the max size is exceeded, the request will fail and the response error code will be RequestEntityTooLarge. If this occurs, the collection of ResourceFiles must be reduced in size. This can be achieved using .zip files, Application Packages, or Docker Containers. — item shape: {autoStorageContainerName?: string, blobPrefix?: string, fileMode?: string, filePath?: string, httpUrl?: string, storageContainerUrl?: string}
  --user-identity: any # Specify either the userName or autoUser property, but not both. — shape: {autoUser?: any, username?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/tasks") $qp)
  let req_body = {"affinityInfo": $affinity_info, "applicationPackageReferences": $application_package_references, "authenticationTokenSettings": $authentication_token_settings, "commandLine": $command_line, "constraints": $constraints, "containerSettings": $container_settings, "dependsOn": $depends_on, "displayName": $display_name, "environmentSettings": $environment_settings, "exitConditions": $exit_conditions, "id": $id, "multiInstanceSettings": $multi_instance_settings, "outputFiles": $output_files, "resourceFiles": $resource_files, "userIdentity": $user_identity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Deletes a Task from the specified Job.
#
# DELETE /jobs/{jobId}/tasks/{taskId}
# operationId: Task_Delete
export def "jobs-tasks delete" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id)} | format pattern "/jobs/{job_id}/tasks/{task_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets information about the specified Task.
#
# GET /jobs/{jobId}/tasks/{taskId}
# operationId: Task_Get
export def "jobs-tasks get" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<affinityInfo: record<affinityId: string>, applicationPackageReferences: table<applicationId: string, version: string>, authenticationTokenSettings: record<access: list<string>>, commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record<password: string, registryServer: string, username: string>, workingDirectory: string>, creationTime: string, dependsOn: record<taskIdRanges: list<record>, taskIds: list<string>>, displayName: string, eTag: string, environmentSettings: table<name: string, value: string>, executionInfo: record<containerInfo: record<containerId: string, error: string, state: string>, endTime: string, exitCode: int, failureInfo: record<category: string, code: string, details: list, message: string>, lastRequeueTime: string, lastRetryTime: string, requeueCount: int, result: string, retryCount: int, startTime: string>, exitConditions: record<default: record<dependencyAction: string, jobAction: string>, exitCodeRanges: list<record>, exitCodes: list<record>, fileUploadError: record<dependencyAction: string, jobAction: string>, preProcessingError: record<dependencyAction: string, jobAction: string>>, id: string, lastModified: string, multiInstanceSettings: record<commonResourceFiles: list<record>, coordinationCommandLine: string, numberOfInstances: int>, nodeInfo: record<affinityId: string, nodeId: string, nodeUrl: string, poolId: string, taskRootDirectory: string, taskRootDirectoryUrl: string>, outputFiles: table<destination: record, filePattern: string, uploadOptions: record>, previousState: string, previousStateTransitionTime: string, resourceFiles: table<autoStorageContainerName: string, blobPrefix: string, fileMode: string, filePath: string, httpUrl: string, storageContainerUrl: string>, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string, userIdentity: record<autoUser: record<elevationLevel: string, scope: string>, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id)} | format pattern "/jobs/{job_id}/tasks/{task_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "$expand": $expand, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Updates the properties of the specified Task.
#
# PUT /jobs/{jobId}/tasks/{taskId}
# operationId: Task_Update
# --constraints shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
export def "jobs-tasks update" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id)} | format pattern "/jobs/{job_id}/tasks/{task_id}") $qp)
  let req_body = {"constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Lists the files in a Task's directory on its Compute Node.
#
# GET /jobs/{jobId}/tasks/{taskId}/files
# operationId: File_ListFromTask
export def "jobs-tasks-files list" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-task-files.
  --recursive: oneof<nothing, bool> # Whether to list children of the Task directory. This parameter can be used in combination with the filter parameter to list specific type of files.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<isDirectory: bool, name: string, properties: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "recursive" $recursive "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id)} | format pattern "/jobs/{job_id}/tasks/{task_id}/files") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "recursive": $recursive, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Deletes the specified Task file from the Compute Node where the Task ran.
#
# DELETE /jobs/{jobId}/tasks/{taskId}/files/{filePath}
# operationId: File_DeleteFromTask
export def "jobs-tasks-files delete" [
  job_id: string
  task_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # Whether to delete children of a directory. If the filePath parameter represents a directory instead of a file, you can set recursive to true to delete the directory and all of the files and subdirectories in it. If recursive is false then the directory must be empty or deletion will fail.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  if ($file_path | is-empty) { error make --unspanned { msg: "path parameter 'filePath' must be non-empty" } }
  let qp = [(serialize-qp "recursive" $recursive "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id), file_path: (encode-path-segment $file_path)} | format pattern "/jobs/{job_id}/tasks/{task_id}/files/{file_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"recursive": $recursive, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Returns the content of the specified Task file.
#
# GET /jobs/{jobId}/tasks/{taskId}/files/{filePath}
# operationId: File_GetFromTask
export def "jobs-tasks-files get" [
  job_id: string
  task_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --ocp-range: string # The byte range to be retrieved. The default is to retrieve the entire file. The format is bytes=startRange-endRange.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  if ($file_path | is-empty) { error make --unspanned { msg: "path parameter 'filePath' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id), file_path: (encode-path-segment $file_path)} | format pattern "/jobs/{job_id}/tasks/{task_id}/files/{file_path}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "ocp-range": $ocp_range, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets the properties of the specified Task file.
#
# HEAD /jobs/{jobId}/tasks/{taskId}/files/{filePath}
# operationId: File_GetPropertiesFromTask
export def "jobs-tasks-files get-properties" [
  job_id: string
  task_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  if ($file_path | is-empty) { error make --unspanned { msg: "path parameter 'filePath' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id), file_path: (encode-path-segment $file_path)} | format pattern "/jobs/{job_id}/tasks/{task_id}/files/{file_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Reactivates a Task, allowing it to run again even if its retry count has been exhausted.
#
# POST /jobs/{jobId}/tasks/{taskId}/reactivate
# operationId: Task_Reactivate
export def "jobs-tasks-reactivate create" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id)} | format pattern "/jobs/{job_id}/tasks/{task_id}/reactivate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Lists all of the subtasks that are associated with the specified multi-instance Task.
#
# GET /jobs/{jobId}/tasks/{taskId}/subtasksinfo
# operationId: Task_ListSubtasks
export def "jobs-tasks-subtasksinfo list-subtasks" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<value: table<containerInfo: record, endTime: string, exitCode: int, failureInfo: record, id: int, nodeInfo: record, previousState: string, previousStateTransitionTime: string, result: string, startTime: string, state: string, stateTransitionTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id)} | format pattern "/jobs/{job_id}/tasks/{task_id}/subtasksinfo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Terminates the specified Task.
#
# POST /jobs/{jobId}/tasks/{taskId}/terminate
# operationId: Task_Terminate
export def "jobs-tasks-terminate create" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), task_id: (encode-path-segment $task_id)} | format pattern "/jobs/{job_id}/tasks/{task_id}/terminate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Terminates the specified Job, marking it as completed.
#
# POST /jobs/{jobId}/terminate
# operationId: Job_Terminate
export def "jobs-terminate create" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --terminate-reason: string
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/terminate") $qp)
  let req_body = {"terminateReason": $terminate_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Lists all of the Job Schedules in the specified Account.
#
# GET /jobschedules
# operationId: JobSchedule_List
export def "jobschedules list-job-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-job-schedules.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Job Schedules can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobSpecification: record, lastModified: string, metadata: list, previousState: string, previousStateTransitionTime: string, schedule: record, state: string, stateTransitionTime: string, stats: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobschedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "$select": $select, "$expand": $expand, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Adds a Job Schedule to the specified Account.
#
# POST /jobschedules
# operationId: JobSchedule_Add
# --jobSpecification shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
# --metadata item shape: {name: string, value: string}
# --schedule shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
export def "jobschedules create-job-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --display-name: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two IDs within an Account that differ only by case).
  job_specification: any # shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
  --metadata: list # The Batch service does not assign any meaning to metadata; it is solely for the use of user code. — item shape: {name: string, value: string}
  schedule: any # shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobschedules" $qp)
  let req_body = {"displayName": $display_name, "id": $id, "jobSpecification": $job_specification, "metadata": $metadata, "schedule": $schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Deletes a Job Schedule from the specified Account.
#
# DELETE /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Delete
export def "jobschedules delete-job-schedule" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'jobScheduleId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_schedule_id: (encode-path-segment $job_schedule_id)} | format pattern "/jobschedules/{job_schedule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets information about the specified Job Schedule.
#
# GET /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Get
export def "jobschedules get-job-schedule" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<creationTime: string, displayName: string, eTag: string, executionInfo: record<endTime: string, nextRunTime: string, recentJob: record<id: string, url: string>>, id: string, jobSpecification: record<commonEnvironmentSettings: list<record>, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string>, displayName: string, jobManagerTask: record<allowLowPriorityNode: bool, applicationPackageReferences: list, authenticationTokenSettings: record, commandLine: string, constraints: record, containerSettings: record, displayName: string, environmentSettings: list, id: string, killJobOnCompletion: bool, outputFiles: list, resourceFiles: list, runExclusive: bool, userIdentity: record>, jobPreparationTask: record<commandLine: string, constraints: record, containerSettings: record, environmentSettings: list, id: string, rerunOnNodeRebootAfterSuccess: bool, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, jobReleaseTask: record<commandLine: string, containerSettings: record, environmentSettings: list, id: string, maxWallClockTime: string, resourceFiles: list, retentionTime: string, userIdentity: record>, metadata: list<record>, networkConfiguration: record<subnetId: string>, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record<autoPoolSpecification: record, poolId: string>, priority: int, usesTaskDependencies: bool>, lastModified: string, metadata: table<name: string, value: string>, previousState: string, previousStateTransitionTime: string, schedule: record<doNotRunAfter: string, doNotRunUntil: string, recurrenceInterval: string, startWindow: string>, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'jobScheduleId' must be non-empty" } }
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_schedule_id: (encode-path-segment $job_schedule_id)} | format pattern "/jobschedules/{job_schedule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "$expand": $expand, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Checks the specified Job Schedule exists.
#
# HEAD /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Exists
export def "jobschedules head-job-schedule-exists" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'jobScheduleId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_schedule_id: (encode-path-segment $job_schedule_id)} | format pattern "/jobschedules/{job_schedule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Updates the properties of the specified Job Schedule.
#
# PATCH /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Patch
# --jobSpecification shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
# --metadata item shape: {name: string, value: string}
# --schedule shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
export def "jobschedules update-job-schedule-by-job-schedule-id" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --job-specification: any # shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
  --metadata: list # If you do not specify this element, existing metadata is left unchanged. — item shape: {name: string, value: string}
  --schedule: any # shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'jobScheduleId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_schedule_id: (encode-path-segment $job_schedule_id)} | format pattern "/jobschedules/{job_schedule_id}") $qp)
  let req_body = {"jobSpecification": $job_specification, "metadata": $metadata, "schedule": $schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Updates the properties of the specified Job Schedule.
#
# PUT /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Update
# --jobSpecification shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
# --metadata item shape: {name: string, value: string}
# --schedule shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
export def "jobschedules update-job-schedule-by-job-schedule-id-1" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  job_specification: any # shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
  --metadata: list # If you do not specify this element, it takes the default value of an empty list; in effect, any existing metadata is deleted. — item shape: {name: string, value: string}
  schedule: any # shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'jobScheduleId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_schedule_id: (encode-path-segment $job_schedule_id)} | format pattern "/jobschedules/{job_schedule_id}") $qp)
  let req_body = {"jobSpecification": $job_specification, "metadata": $metadata, "schedule": $schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Disables a Job Schedule.
#
# POST /jobschedules/{jobScheduleId}/disable
# operationId: JobSchedule_Disable
export def "jobschedules-disable disable-job-schedule" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'jobScheduleId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_schedule_id: (encode-path-segment $job_schedule_id)} | format pattern "/jobschedules/{job_schedule_id}/disable") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Enables a Job Schedule.
#
# POST /jobschedules/{jobScheduleId}/enable
# operationId: JobSchedule_Enable
export def "jobschedules-enable enable-job-schedule" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'jobScheduleId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_schedule_id: (encode-path-segment $job_schedule_id)} | format pattern "/jobschedules/{job_schedule_id}/enable") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Lists the Jobs that have been created under the specified Job Schedule.
#
# GET /jobschedules/{jobScheduleId}/jobs
# operationId: Job_ListFromJobSchedule
export def "jobschedules-jobs list-from-schedule" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-jobs-in-a-job-schedule.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Jobs can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<commonEnvironmentSettings: list, constraints: record, creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobManagerTask: record, jobPreparationTask: record, jobReleaseTask: record, lastModified: string, metadata: list, networkConfiguration: record, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record, url: string, usesTaskDependencies: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'jobScheduleId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_schedule_id: (encode-path-segment $job_schedule_id)} | format pattern "/jobschedules/{job_schedule_id}/jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "$select": $select, "$expand": $expand, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Terminates a Job Schedule.
#
# POST /jobschedules/{jobScheduleId}/terminate
# operationId: JobSchedule_Terminate
export def "jobschedules-terminate create-job-schedule" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'jobScheduleId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_schedule_id: (encode-path-segment $job_schedule_id)} | format pattern "/jobschedules/{job_schedule_id}/terminate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets lifetime summary statistics for all of the Jobs in the specified Account.
#
# GET /lifetimejobstats
# operationId: Job_GetAllLifetimeStatistics
export def "lifetimejobstats get-job-list-lifetime-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lifetimejobstats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets lifetime summary statistics for all of the Pools in the specified Account.
#
# GET /lifetimepoolstats
# operationId: Pool_GetAllLifetimeStatistics
export def "lifetimepoolstats get-pool-list-lifetime-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<lastUpdateTime: string, resourceStats: record<avgCPUPercentage: float, avgDiskGiB: float, avgMemoryGiB: float, diskReadGiB: float, diskReadIOps: int, diskWriteGiB: float, diskWriteIOps: int, lastUpdateTime: string, networkReadGiB: float, networkWriteGiB: float, peakDiskGiB: float, peakMemoryGiB: float, startTime: string>, startTime: string, url: string, usageStats: record<dedicatedCoreTime: string, lastUpdateTime: string, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lifetimepoolstats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets the number of Compute Nodes in each state, grouped by Pool.
#
# GET /nodecounts
# operationId: Account_ListPoolNodeCounts
export def "nodecounts list-account-pool-node-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch.
  --maxresults: int # The maximum number of items to return in the response. (format: int32, default: 10)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<dedicated: record, lowPriority: record, poolId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodecounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Lists all of the Pools in the specified Account.
#
# GET /pools
# operationId: Pool_List
export def "pools list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-pools.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Pools can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list, applicationPackageReferences: list, autoScaleEvaluationInterval: string, autoScaleFormula: string, autoScaleRun: record, certificateReferences: list, cloudServiceConfiguration: record, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, displayName: string, eTag: string, enableAutoScale: bool, enableInterNodeCommunication: bool, id: string, lastModified: string, maxTasksPerNode: int, metadata: list, mountConfiguration: list, networkConfiguration: record, resizeErrors: list, resizeTimeout: string, startTask: record, state: string, stateTransitionTime: string, stats: record, targetDedicatedNodes: int, targetLowPriorityNodes: int, taskSchedulingPolicy: record, url: string, userAccounts: list, virtualMachineConfiguration: record, vmSize: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "$select": $select, "$expand": $expand, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Adds a Pool to the specified Account.
#
# POST /pools
# operationId: Pool_Add
# --applicationPackageReferences item shape: {applicationId: string, version?: string}
# --certificateReferences item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list<string>}
# --cloudServiceConfiguration shape: {osFamily: string, osVersion?: string}
# --metadata item shape: {name: string, value: string}
# --mountConfiguration item shape: {azureBlobFileSystemConfiguration?: any, azureFileShareConfiguration?: any, cifsMountConfiguration?: any, nfsMountConfiguration?: any}
# --networkConfiguration shape: {dynamicVNetAssignmentScope?: "none"|"job", endpointConfiguration?: any, publicIPs?: list<string>, subnetId?: string}
# --startTask shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
# --taskSchedulingPolicy shape: {nodeFillType: "spread"|"pack"}
# --userAccounts item shape: {elevationLevel?: "nonadmin"|"admin", linuxUserConfiguration?: any, name: string, password: string, windowsUserConfiguration?: any}
# --virtualMachineConfiguration shape: {containerConfiguration?: any, dataDisks?: list, imageReference: any, licenseType?: string, nodeAgentSKUId: string, windowsConfiguration?: any}
export def "pools create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --application-licenses: list<string> # The list of application licenses must be a subset of available Batch service application licenses. If a license is requested which is not supported, Pool creation will fail.
  --application-package-references: list # Changes to Package references affect all new Nodes joining the Pool, but do not affect Compute Nodes that are already in the Pool until they are rebooted or reimaged. There is a maximum of 10 Package references on any given Pool. — item shape: {applicationId: string, version?: string}
  --auto-scale-evaluation-interval: string # The default value is 15 minutes. The minimum and maximum value are 5 minutes and 168 hours respectively. If you specify a value less than 5 minutes or greater than 168 hours, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
  --auto-scale-formula: string # This property must not be specified if enableAutoScale is set to false. It is required if enableAutoScale is set to true. The formula is checked for validity before the Pool is created. If the formula is not valid, the Batch service rejects the request with detailed error information. For more information about specifying this formula, see 'Automatically scale Compute Nodes in an Azure Batch Pool' (https://azure.microsoft.com/documentation/articles/batch-automatic-scaling/).
  --certificate-references: list # For Windows Nodes, the Batch service installs the Certificates to the specified Certificate store and location. For Linux Compute Nodes, the Certificates are stored in a directory inside the Task working directory and an environment variable AZ_BATCH_CERTIFICATES_DIR is supplied to the Task to query for this location. For Certificates with visibility of 'remoteUser', a 'certs' directory is created in the user's home directory (e.g., /home/{user-name}/certs) and Certificates are placed in that directory. — item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list<string>}
  --cloud-service-configuration: any # shape: {osFamily: string, osVersion?: string}
  --display-name: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  --enable-auto-scale: oneof<nothing, bool> # If false, at least one of targetDedicateNodes and targetLowPriorityNodes must be specified. If true, the autoScaleFormula property is required and the Pool automatically resizes according to the formula. The default value is false.
  --enable-inter-node-communication: oneof<nothing, bool> # Enabling inter-node communication limits the maximum size of the Pool due to deployment restrictions on the Compute Nodes of the Pool. This may result in the Pool not reaching its desired size. The default value is false.
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two Pool IDs within an Account that differ only by case).
  --max-tasks-per-node: int # The default value is 1. The maximum value is the smaller of 4 times the number of cores of the vmSize of the Pool or 256. (format: int32)
  --metadata: list # The Batch service does not assign any meaning to metadata; it is solely for the use of user code. — item shape: {name: string, value: string}
  --mount-configuration: list # Mount the storage using Azure fileshare, NFS, CIFS or Blobfuse based file system. — item shape: {azureBlobFileSystemConfiguration?: any, azureFileShareConfiguration?: any, cifsMountConfiguration?: any, nfsMountConfiguration?: any}
  --network-configuration: any # The network configuration for a Pool. — shape: {dynamicVNetAssignmentScope?: "none"|"job", endpointConfiguration?: any, publicIPs?: list<string>, subnetId?: string}
  --resize-timeout: string # This timeout applies only to manual scaling; it has no effect when enableAutoScale is set to true. The default value is 15 minutes. The minimum value is 5 minutes. If you specify a value less than 5 minutes, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
  --start-task: any # Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. In some cases the StartTask may be re-run even though the Compute Node was not rebooted. Special care should be taken to avoid StartTasks which create breakaway process or install/launch services from the StartTask working directory, as this will block Batch from being able to re-run the StartTask. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
  --target-dedicated-nodes: int # This property must not be specified if enableAutoScale is set to true. If enableAutoScale is set to false, then you must set either targetDedicatedNodes, targetLowPriorityNodes, or both. (format: int32)
  --target-low-priority-nodes: int # This property must not be specified if enableAutoScale is set to true. If enableAutoScale is set to false, then you must set either targetDedicatedNodes, targetLowPriorityNodes, or both. (format: int32)
  --task-scheduling-policy: any # shape: {nodeFillType: "spread"|"pack"}
  --user-accounts: list # item shape: {elevationLevel?: "nonadmin"|"admin", linuxUserConfiguration?: any, name: string, password: string, windowsUserConfiguration?: any}
  --virtual-machine-configuration: any # shape: {containerConfiguration?: any, dataDisks?: list, imageReference: any, licenseType?: string, nodeAgentSKUId: string, windowsConfiguration?: any}
  vm_size: string # For information about available sizes of virtual machines for Cloud Services Pools (pools created with cloudServiceConfiguration), see Sizes for Cloud Services (https://azure.microsoft.com/documentation/articles/cloud-services-sizes-specs/). Batch supports all Cloud Services VM sizes except ExtraSmall, A1V2 and A2V2. For information about available VM sizes for Pools using Images from the Virtual Machines Marketplace (pools created with virtualMachineConfiguration) see Sizes for Virtual Machines (Linux) (https://azure.microsoft.com/documentation/articles/virtual-machines-linux-sizes/) or Sizes for Virtual Machines (Windows) (https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/). Batch supports all Azure VM sizes except STANDARD_A0 and those with premium storage (STANDARD_GS, STANDARD_DS, and STANDARD_DSV2 series).
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pools" $qp)
  let req_body = {"applicationLicenses": $application_licenses, "applicationPackageReferences": $application_package_references, "autoScaleEvaluationInterval": $auto_scale_evaluation_interval, "autoScaleFormula": $auto_scale_formula, "certificateReferences": $certificate_references, "cloudServiceConfiguration": $cloud_service_configuration, "displayName": $display_name, "enableAutoScale": $enable_auto_scale, "enableInterNodeCommunication": $enable_inter_node_communication, "id": $id, "maxTasksPerNode": $max_tasks_per_node, "metadata": $metadata, "mountConfiguration": $mount_configuration, "networkConfiguration": $network_configuration, "resizeTimeout": $resize_timeout, "startTask": $start_task, "targetDedicatedNodes": $target_dedicated_nodes, "targetLowPriorityNodes": $target_low_priority_nodes, "taskSchedulingPolicy": $task_scheduling_policy, "userAccounts": $user_accounts, "virtualMachineConfiguration": $virtual_machine_configuration, "vmSize": $vm_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Deletes a Pool from the specified Account.
#
# DELETE /pools/{poolId}
# operationId: Pool_Delete
export def "pools delete" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets information about the specified Pool.
#
# GET /pools/{poolId}
# operationId: Pool_Get
export def "pools get" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackageReferences: table<applicationId: string, version: string>, autoScaleEvaluationInterval: string, autoScaleFormula: string, autoScaleRun: record<error: record<code: string, message: string, values: list>, results: string, timestamp: string>, certificateReferences: table<storeLocation: string, storeName: string, thumbprint: string, thumbprintAlgorithm: string, visibility: list>, cloudServiceConfiguration: record<osFamily: string, osVersion: string>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, displayName: string, eTag: string, enableAutoScale: bool, enableInterNodeCommunication: bool, id: string, lastModified: string, maxTasksPerNode: int, metadata: table<name: string, value: string>, mountConfiguration: table<azureBlobFileSystemConfiguration: record, azureFileShareConfiguration: record, cifsMountConfiguration: record, nfsMountConfiguration: record>, networkConfiguration: record<dynamicVNetAssignmentScope: string, endpointConfiguration: record<inboundNATPools: list>, publicIPs: list<string>, subnetId: string>, resizeErrors: table<code: string, message: string, values: list>, resizeTimeout: string, startTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, maxTaskRetryCount: int, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, state: string, stateTransitionTime: string, stats: record<lastUpdateTime: string, resourceStats: record<avgCPUPercentage: float, avgDiskGiB: float, avgMemoryGiB: float, diskReadGiB: float, diskReadIOps: int, diskWriteGiB: float, diskWriteIOps: int, lastUpdateTime: string, networkReadGiB: float, networkWriteGiB: float, peakDiskGiB: float, peakMemoryGiB: float, startTime: string>, startTime: string, url: string, usageStats: record<dedicatedCoreTime: string, lastUpdateTime: string, startTime: string>>, targetDedicatedNodes: int, targetLowPriorityNodes: int, taskSchedulingPolicy: record<nodeFillType: string>, url: string, userAccounts: table<elevationLevel: string, linuxUserConfiguration: record, name: string, password: string, windowsUserConfiguration: record>, virtualMachineConfiguration: record<containerConfiguration: record<containerImageNames: list, containerRegistries: list, type: string>, dataDisks: list<record>, imageReference: record<offer: string, publisher: string, sku: string, version: string, virtualMachineImageId: string>, licenseType: string, nodeAgentSKUId: string, windowsConfiguration: record<enableAutomaticUpdates: bool>>, vmSize: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "$expand": $expand, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets basic properties of a Pool.
#
# HEAD /pools/{poolId}
# operationId: Pool_Exists
export def "pools head-exists" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Updates the properties of the specified Pool.
#
# PATCH /pools/{poolId}
# operationId: Pool_Patch
# --applicationPackageReferences item shape: {applicationId: string, version?: string}
# --certificateReferences item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list<string>}
# --metadata item shape: {name: string, value: string}
# --startTask shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
export def "pools update" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --application-package-references: list # Changes to Package references affect all new Nodes joining the Pool, but do not affect Compute Nodes that are already in the Pool until they are rebooted or reimaged. If this element is present, it replaces any existing Package references. If you specify an empty collection, then all Package references are removed from the Pool. If omitted, any existing Package references are left unchanged. — item shape: {applicationId: string, version?: string}
  --certificate-references: list # If this element is present, it replaces any existing Certificate references configured on the Pool. If omitted, any existing Certificate references are left unchanged. For Windows Nodes, the Batch service installs the Certificates to the specified Certificate store and location. For Linux Compute Nodes, the Certificates are stored in a directory inside the Task working directory and an environment variable AZ_BATCH_CERTIFICATES_DIR is supplied to the Task to query for this location. For Certificates with visibility of 'remoteUser', a 'certs' directory is created in the user's home directory (e.g., /home/{user-name}/certs) and Certificates are placed in that directory. — item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list<string>}
  --metadata: list # If this element is present, it replaces any existing metadata configured on the Pool. If you specify an empty collection, any metadata is removed from the Pool. If omitted, any existing metadata is left unchanged. — item shape: {name: string, value: string}
  --start-task: any # Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. In some cases the StartTask may be re-run even though the Compute Node was not rebooted. Special care should be taken to avoid StartTasks which create breakaway process or install/launch services from the StartTask working directory, as this will block Batch from being able to re-run the StartTask. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}") $qp)
  let req_body = {"applicationPackageReferences": $application_package_references, "certificateReferences": $certificate_references, "metadata": $metadata, "startTask": $start_task} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Disables automatic scaling for a Pool.
#
# POST /pools/{poolId}/disableautoscale
# operationId: Pool_DisableAutoScale
export def "pools-disableautoscale disable-auto-scale" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}/disableautoscale") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Enables automatic scaling for a Pool.
#
# POST /pools/{poolId}/enableautoscale
# operationId: Pool_EnableAutoScale
export def "pools-enableautoscale enable-auto-scale" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --auto-scale-evaluation-interval: string # The default value is 15 minutes. The minimum and maximum value are 5 minutes and 168 hours respectively. If you specify a value less than 5 minutes or greater than 168 hours, the Batch service rejects the request with an invalid property value error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). If you specify a new interval, then the existing autoscale evaluation schedule will be stopped and a new autoscale evaluation schedule will be started, with its starting time being the time when this request was issued. (format: duration)
  --auto-scale-formula: string # The formula is checked for validity before it is applied to the Pool. If the formula is not valid, the Batch service rejects the request with detailed error information. For more information about specifying this formula, see Automatically scale Compute Nodes in an Azure Batch Pool (https://azure.microsoft.com/en-us/documentation/articles/batch-automatic-scaling).
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}/enableautoscale") $qp)
  let req_body = {"autoScaleEvaluationInterval": $auto_scale_evaluation_interval, "autoScaleFormula": $auto_scale_formula} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Gets the result of evaluating an automatic scaling formula on the Pool.
#
# POST /pools/{poolId}/evaluateautoscale
# operationId: Pool_EvaluateAutoScale
export def "pools-evaluateautoscale create-evaluate-auto-scale" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  auto_scale_formula: string # The formula is validated and its results calculated, but it is not applied to the Pool. To apply the formula to the Pool, 'Enable automatic scaling on a Pool'. For more information about specifying this formula, see Automatically scale Compute Nodes in an Azure Batch Pool (https://azure.microsoft.com/en-us/documentation/articles/batch-automatic-scaling).
]: any -> record<error: record<code: string, message: string, values: list<record>>, results: string, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}/evaluateautoscale") $qp)
  let req_body = {"autoScaleFormula": $auto_scale_formula} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Lists the Compute Nodes in the specified Pool.
#
# GET /pools/{poolId}/nodes
# operationId: ComputeNode_List
export def "pools-nodes list-compute" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-nodes-in-a-pool.
  --select: string # An OData $select clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Compute Nodes can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<affinityId: string, allocationTime: string, certificateReferences: list, endpointConfiguration: record, errors: list, id: string, ipAddress: string, isDedicated: bool, lastBootTime: string, nodeAgentInfo: record, recentTasks: list, runningTasksCount: int, schedulingState: string, startTask: record, startTaskInfo: record, state: string, stateTransitionTime: string, totalTasksRun: int, totalTasksSucceeded: int, url: string, vmSize: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}/nodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "$select": $select, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets information about the specified Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}
# operationId: ComputeNode_Get
export def "pools-nodes get-compute" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<affinityId: string, allocationTime: string, certificateReferences: table<storeLocation: string, storeName: string, thumbprint: string, thumbprintAlgorithm: string, visibility: list>, endpointConfiguration: record<inboundEndpoints: list<record>>, errors: table<code: string, errorDetails: list, message: string>, id: string, ipAddress: string, isDedicated: bool, lastBootTime: string, nodeAgentInfo: record<lastUpdateTime: string, version: string>, recentTasks: table<executionInfo: record, jobId: string, subtaskId: int, taskId: string, taskState: string, taskUrl: string>, runningTasksCount: int, schedulingState: string, startTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, maxTaskRetryCount: int, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, startTaskInfo: record<containerInfo: record<containerId: string, error: string, state: string>, endTime: string, exitCode: int, failureInfo: record<category: string, code: string, details: list, message: string>, lastRetryTime: string, result: string, retryCount: int, startTime: string, state: string>, state: string, stateTransitionTime: string, totalTasksRun: int, totalTasksSucceeded: int, url: string, vmSize: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Disables Task scheduling on the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/disablescheduling
# operationId: ComputeNode_DisableScheduling
export def "pools-nodes-disablescheduling disable-compute-scheduling" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --node-disable-scheduling-option: string@node-disable-scheduling-option-completer # The default value is requeue.
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}/disablescheduling") $qp)
  let req_body = {"nodeDisableSchedulingOption": $node_disable_scheduling_option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Enables Task scheduling on the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/enablescheduling
# operationId: ComputeNode_EnableScheduling
export def "pools-nodes-enablescheduling enable-compute-scheduling" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}/enablescheduling") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Lists all of the files in Task directories on the specified Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}/files
# operationId: File_ListFromComputeNode
export def "pools-nodes-files list-from-compute" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-compute-node-files.
  --recursive: oneof<nothing, bool> # Whether to list children of a directory.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<isDirectory: bool, name: string, properties: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "recursive" $recursive "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}/files") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "recursive": $recursive, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Deletes the specified file from the Compute Node.
#
# DELETE /pools/{poolId}/nodes/{nodeId}/files/{filePath}
# operationId: File_DeleteFromComputeNode
export def "pools-nodes-files delete-from-compute" [
  pool_id: string
  node_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # Whether to delete children of a directory. If the filePath parameter represents a directory instead of a file, you can set recursive to true to delete the directory and all of the files and subdirectories in it. If recursive is false then the directory must be empty or deletion will fail.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  if ($file_path | is-empty) { error make --unspanned { msg: "path parameter 'filePath' must be non-empty" } }
  let qp = [(serialize-qp "recursive" $recursive "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id), file_path: (encode-path-segment $file_path)} | format pattern "/pools/{pool_id}/nodes/{node_id}/files/{file_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"recursive": $recursive, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Returns the content of the specified Compute Node file.
#
# GET /pools/{poolId}/nodes/{nodeId}/files/{filePath}
# operationId: File_GetFromComputeNode
export def "pools-nodes-files get-from-compute" [
  pool_id: string
  node_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --ocp-range: string # The byte range to be retrieved. The default is to retrieve the entire file. The format is bytes=startRange-endRange.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  if ($file_path | is-empty) { error make --unspanned { msg: "path parameter 'filePath' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id), file_path: (encode-path-segment $file_path)} | format pattern "/pools/{pool_id}/nodes/{node_id}/files/{file_path}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "ocp-range": $ocp_range, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets the properties of the specified Compute Node file.
#
# HEAD /pools/{poolId}/nodes/{nodeId}/files/{filePath}
# operationId: File_GetPropertiesFromComputeNode
export def "pools-nodes-files get-properties-from-compute" [
  pool_id: string
  node_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  if ($file_path | is-empty) { error make --unspanned { msg: "path parameter 'filePath' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id), file_path: (encode-path-segment $file_path)} | format pattern "/pools/{pool_id}/nodes/{node_id}/files/{file_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Gets the Remote Desktop Protocol file for the specified Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}/rdp
# operationId: ComputeNode_GetRemoteDesktop
export def "pools-nodes-rdp get-compute-remote-desktop" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}/rdp") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Restarts the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/reboot
# operationId: ComputeNode_Reboot
export def "pools-nodes-reboot create-compute" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --node-reboot-option: string@node-reboot-option-completer # The default value is requeue.
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}/reboot") $qp)
  let req_body = {"nodeRebootOption": $node_reboot_option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Reinstalls the operating system on the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/reimage
# operationId: ComputeNode_Reimage
export def "pools-nodes-reimage create-compute" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --node-reimage-option: string@node-reimage-option-completer # The default value is requeue.
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}/reimage") $qp)
  let req_body = {"nodeReimageOption": $node_reimage_option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Gets the settings required for remote login to a Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}/remoteloginsettings
# operationId: ComputeNode_GetRemoteLoginSettings
export def "pools-nodes-remoteloginsettings get-compute-remote-login-settings" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<remoteLoginIPAddress: string, remoteLoginPort: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}/remoteloginsettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Upload Azure Batch service log files from the specified Compute Node to Azure Blob Storage.
#
# POST /pools/{poolId}/nodes/{nodeId}/uploadbatchservicelogs
# operationId: ComputeNode_UploadBatchServiceLogs
export def "pools-nodes-uploadbatchservicelogs upload-compute-batch-service-logs" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  container_url: string # The URL must include a Shared Access Signature (SAS) granting write permissions to the container. The SAS duration must allow enough time for the upload to finish. The start time for SAS is optional and recommended to not be specified.
  --end-time: string # Any log file containing a log message in the time range will be uploaded. This means that the operation might retrieve more logs than have been requested since the entire log file is always uploaded, but the operation should not retrieve fewer logs than have been requested. If omitted, the default is to upload all logs available after the startTime. (format: date-time)
  start_time: string # Any log file containing a log message in the time range will be uploaded. This means that the operation might retrieve more logs than have been requested since the entire log file is always uploaded, but the operation should not retrieve fewer logs than have been requested. (format: date-time)
]: any -> record<numberOfFilesUploaded: int, virtualDirectoryName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}/uploadbatchservicelogs") $qp)
  let req_body = {"containerUrl": $container_url, "endTime": $end_time, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Adds a user Account to the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/users
# operationId: ComputeNode_AddUser
export def "pools-nodes-users create-compute" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --expiry-time: string # If omitted, the default is 1 day from the current time. For Linux Compute Nodes, the expiryTime has a precision up to a day. (format: date-time)
  --is-admin: oneof<nothing, bool> # The default value is false.
  name: string
  --password: string # The password is required for Windows Compute Nodes (those created with 'cloudServiceConfiguration', or created with 'virtualMachineConfiguration' using a Windows Image reference). For Linux Compute Nodes, the password can optionally be specified along with the sshPublicKey property.
  --ssh-public-key: string # The public key should be compatible with OpenSSH encoding and should be base 64 encoded. This property can be specified only for Linux Compute Nodes. If this is specified for a Windows Compute Node, then the Batch service rejects the request; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request).
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/pools/{pool_id}/nodes/{node_id}/users") $qp)
  let req_body = {"expiryTime": $expiry_time, "isAdmin": $is_admin, "name": $name, "password": $password, "sshPublicKey": $ssh_public_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Deletes a user Account from the specified Compute Node.
#
# DELETE /pools/{poolId}/nodes/{nodeId}/users/{userName}
# operationId: ComputeNode_DeleteUser
export def "pools-nodes-users delete-compute" [
  pool_id: string
  node_id: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id), user_name: (encode-path-segment $user_name)} | format pattern "/pools/{pool_id}/nodes/{node_id}/users/{user_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Updates the password and expiration time of a user Account on the specified Compute Node.
#
# PUT /pools/{poolId}/nodes/{nodeId}/users/{userName}
# operationId: ComputeNode_UpdateUser
export def "pools-nodes-users update-compute" [
  pool_id: string
  node_id: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --expiry-time: string # If omitted, the default is 1 day from the current time. For Linux Compute Nodes, the expiryTime has a precision up to a day. (format: date-time)
  --password: string # The password is required for Windows Compute Nodes (those created with 'cloudServiceConfiguration', or created with 'virtualMachineConfiguration' using a Windows Image reference). For Linux Compute Nodes, the password can optionally be specified along with the sshPublicKey property. If omitted, any existing password is removed.
  --ssh-public-key: string # The public key should be compatible with OpenSSH encoding and should be base 64 encoded. This property can be specified only for Linux Compute Nodes. If this is specified for a Windows Compute Node, then the Batch service rejects the request; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). If omitted, any existing SSH public key is removed.
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'nodeId' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id), node_id: (encode-path-segment $node_id), user_name: (encode-path-segment $user_name)} | format pattern "/pools/{pool_id}/nodes/{node_id}/users/{user_name}") $qp)
  let req_body = {"expiryTime": $expiry_time, "password": $password, "sshPublicKey": $ssh_public_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Removes Compute Nodes from the specified Pool.
#
# POST /pools/{poolId}/removenodes
# operationId: Pool_RemoveNodes
export def "pools-remove-nodes delete" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --node-deallocation-option: string@node-deallocation-option-completer # The default value is requeue.
  node_list: list<string>
  --resize-timeout: string # The default value is 15 minutes. The minimum value is 5 minutes. If you specify a value less than 5 minutes, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}/removenodes") $qp)
  let req_body = {"nodeDeallocationOption": $node_deallocation_option, "nodeList": $node_list, "resizeTimeout": $resize_timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Changes the number of Compute Nodes that are assigned to a Pool.
#
# POST /pools/{poolId}/resize
# operationId: Pool_Resize
export def "pools-resize resize" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --node-deallocation-option: string@node-deallocation-option-completer # The default value is requeue.
  --resize-timeout: string # The default value is 15 minutes. The minimum value is 5 minutes. If you specify a value less than 5 minutes, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
  --target-dedicated-nodes: int # format: int32
  --target-low-priority-nodes: int # format: int32
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}/resize") $qp)
  let req_body = {"nodeDeallocationOption": $node_deallocation_option, "resizeTimeout": $resize_timeout, "targetDedicatedNodes": $target_dedicated_nodes, "targetLowPriorityNodes": $target_low_priority_nodes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Stops an ongoing resize operation on the Pool.
#
# POST /pools/{poolId}/stopresize
# operationId: Pool_StopResize
export def "pools-stopresize stop-resize" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}/stopresize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Updates the properties of the specified Pool.
#
# POST /pools/{poolId}/updateproperties
# operationId: Pool_UpdateProperties
# --applicationPackageReferences item shape: {applicationId: string, version?: string}
# --certificateReferences item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list<string>}
# --metadata item shape: {name: string, value: string}
# --startTask shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
export def "pools-update-properties update" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  application_package_references: list # The list replaces any existing Application Package references on the Pool. Changes to Application Package references affect all new Compute Nodes joining the Pool, but do not affect Compute Nodes that are already in the Pool until they are rebooted or reimaged. There is a maximum of 10 Application Package references on any given Pool. If omitted, or if you specify an empty collection, any existing Application Packages references are removed from the Pool. A maximum of 10 references may be specified on a given Pool. — item shape: {applicationId: string, version?: string}
  certificate_references: list # This list replaces any existing Certificate references configured on the Pool. If you specify an empty collection, any existing Certificate references are removed from the Pool. For Windows Nodes, the Batch service installs the Certificates to the specified Certificate store and location. For Linux Compute Nodes, the Certificates are stored in a directory inside the Task working directory and an environment variable AZ_BATCH_CERTIFICATES_DIR is supplied to the Task to query for this location. For Certificates with visibility of 'remoteUser', a 'certs' directory is created in the user's home directory (e.g., /home/{user-name}/certs) and Certificates are placed in that directory. — item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list<string>}
  metadata: list # This list replaces any existing metadata configured on the Pool. If omitted, or if you specify an empty collection, any existing metadata is removed from the Pool. — item shape: {name: string, value: string}
  --start-task: any # Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. In some cases the StartTask may be re-run even though the Compute Node was not rebooted. Special care should be taken to avoid StartTasks which create breakaway process or install/launch services from the StartTask working directory, as this will block Batch from being able to re-run the StartTask. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pool_id | is-empty) { error make --unspanned { msg: "path parameter 'poolId' must be non-empty" } }
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/pools/{pool_id}/updateproperties") $qp)
  let req_body = {"applicationPackageReferences": $application_package_references, "certificateReferences": $certificate_references, "metadata": $metadata, "startTask": $start_task} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json; odata=minimalmetadata" $req_body {query: ({"timeout": $timeout, "api-version": $api_version} | compact), body: $req_body}
}

# Lists the usage metrics, aggregated by Pool across individual time intervals, for the specified Account.
#
# GET /poolusagemetrics
# operationId: Pool_ListUsageMetrics
export def "poolusagemetrics list-pool-usage-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --starttime: string # The earliest time from which to include metrics. This must be at least two and a half hours before the current time. If not specified this defaults to the start time of the last aggregation interval currently available. (format: date-time)
  --endtime: string # The latest time from which to include metrics. This must be at least two hours before the current time. If not specified this defaults to the end time of the last aggregation interval currently available. (format: date-time)
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-account-usage-metrics.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 results will be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<endTime: string, poolId: string, startTime: string, totalCoreHours: float, vmSize: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starttime" $starttime "scalar") (serialize-qp "endtime" $endtime "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/poolusagemetrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"starttime": $starttime, "endtime": $endtime, "$filter": $filter, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}

# Lists all Virtual Machine Images supported by the Azure Batch service.
#
# GET /supportedimages
# operationId: Account_ListSupportedImages
export def "supportedimages list-account-supported-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-support-images.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 results will be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<batchSupportEndOfLife: string, capabilities: list, imageReference: record, nodeAgentSKUId: string, osType: string, verificationType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/supportedimages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$filter": $filter, "maxresults": $maxresults, "timeout": $timeout, "api-version": $api_version} | compact), body: null}
}
