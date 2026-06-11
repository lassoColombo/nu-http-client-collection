# Auto-generated client for BatchService v2019-08-01.10.0
# Source: https://api.apis.guru/v2/specs/azure.com/batch-BatchService/2019-08-01.10.0/swagger.json
# Auth: --token flag or $env.BATCHSERVICE_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BATCHSERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def certificateFormat-completer [] { ["cer" "pfx"] }
def onAllTasksComplete-completer [] { ["noaction" "terminatejob"] }
def onTaskFailure-completer [] { ["noaction" "performexitoptionsjobaction"] }
def disableTasks-completer [] { ["requeue" "terminate" "wait"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }
def nodeDisableSchedulingOption-completer [] { ["requeue" "taskcompletion" "terminate"] }
def nodeRebootOption-completer [] { ["requeue" "retaineddata" "taskcompletion" "terminate"] }
def nodeReimageOption-completer [] { ["requeue" "retaineddata" "taskcompletion" "terminate"] }
def nodeDeallocationOption-completer [] { ["requeue" "retaineddata" "taskcompletion" "terminate"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applications List" } } | get name | first)
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
export def "applications List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 applications can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<displayName: string, id: string, versions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/applications" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified Application.
#
# GET /applications/{applicationId}
# operationId: Application_Get
export def "applications Get" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<displayName: string, id: string, versions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($applicationId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all of the Certificates that have been added to the specified Account.
#
# GET /certificates
# operationId: Certificate_List
export def "certificates List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-certificates.
  --select: string # An OData $select clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Certificates can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<deleteCertificateError: record, previousState: string, previousStateTransitionTime: string, publicData: string, state: string, stateTransitionTime: string, thumbprint: string, thumbprintAlgorithm: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a Certificate to the specified Account.
#
# POST /certificates
# operationId: Certificate_Add
export def "certificates Add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --certificateFormat: string@certificateFormat-completer
  data: string
  --password: string # This is required if the Certificate format is pfx. It should be omitted if the Certificate format is cer.
  thumbprint: string
  thumbprintAlgorithm: string
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates" $qp)
  let body = {certificateFormat: $certificateFormat, data: $data, password: $password, thumbprint: $thumbprint, thumbprintAlgorithm: $thumbprintAlgorithm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a Certificate from the specified Account.
#
# DELETE /certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})
# operationId: Certificate_Delete
export def "certificatesthumbprint-algorithm-thumbprint-algorithm-thumbprint-thumbprint Delete" [
  thumbprintAlgorithm: string
  thumbprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates(thumbprintAlgorithm=($thumbprintAlgorithm),thumbprint=($thumbprint))" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified Certificate.
#
# GET /certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})
# operationId: Certificate_Get
export def "certificatesthumbprint-algorithm-thumbprint-algorithm-thumbprint-thumbprint Get" [
  thumbprintAlgorithm: string
  thumbprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # An OData $select clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<deleteCertificateError: record<code: string, message: string, values: list<record>>, previousState: string, previousStateTransitionTime: string, publicData: string, state: string, stateTransitionTime: string, thumbprint: string, thumbprintAlgorithm: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates(thumbprintAlgorithm=($thumbprintAlgorithm),thumbprint=($thumbprint))" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels a failed deletion of a Certificate from the specified Account.
#
# POST /certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})/canceldelete
# operationId: Certificate_CancelDeletion
export def "certificatesthumbprint-algorithm-thumbprint-algorithm-thumbprint-thumbprint-canceldelete CancelDeletion" [
  thumbprintAlgorithm: string
  thumbprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates(thumbprintAlgorithm=($thumbprintAlgorithm),thumbprint=($thumbprint))/canceldelete" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all of the Jobs in the specified Account.
#
# GET /jobs
# operationId: Job_List
export def "jobs List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-jobs.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Jobs can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<commonEnvironmentSettings: list, constraints: record, creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobManagerTask: record, jobPreparationTask: record, jobReleaseTask: record, lastModified: string, metadata: list, networkConfiguration: record, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record, url: string, usesTaskDependencies: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobs" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "jobs Add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --commonEnvironmentSettings: list # Individual Tasks can override an environment setting specified here by specifying the same setting name with a different value. — item shape: {name: string, value?: string}
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
  --displayName: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two IDs within an Account that differ only by case).
  --jobManagerTask: any # The Job Manager Task is automatically started when the Job is created. The Batch service tries to schedule the Job Manager Task before any other Tasks in the Job. When shrinking a Pool, the Batch service tries to preserve Nodes where Job Manager Tasks are running for as long as possible (that is, Compute Nodes running 'normal' Tasks are removed before Compute Nodes running Job Manager Tasks). When a Job Manager Task fails and needs to be restarted, the system tries to schedule it at the highest priority. If there are no idle Compute Nodes available, the system may terminate one of the running Tasks in the Pool and return it to the queue in order to make room for the Job Manager Task to restart. Note that a Job Manager Task in one Job does not have priority over Tasks in other Jobs. Across Jobs, only Job level priorities are observed. For example, if a Job Manager in a priority 0 Job needs to be restarted, it will not displace Tasks of a priority 1 Job. Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. — shape: {allowLowPriorityNode?: bool, applicationPackageReferences?: list, authenticationTokenSettings?: any, commandLine: string, constraints?: any, containerSettings?: any, displayName?: string, environmentSettings?: list, id: string, killJobOnCompletion?: bool, outputFiles?: list, resourceFiles?: list, runExclusive?: bool, userIdentity?: any}
  --jobPreparationTask: any # You can use Job Preparation to prepare a Node to run Tasks for the Job. Activities commonly performed in Job Preparation include: Downloading common resource files used by all the Tasks in the Job. The Job Preparation Task can download these common resource files to the shared location on the Node. (AZ_BATCH_NODE_ROOT_DIR\shared), or starting a local service on the Node so that all Tasks of that Job can communicate with it. If the Job Preparation Task fails (that is, exhausts its retry count before exiting with exit code 0), Batch will not run Tasks of this Job on the Node. The Compute Node remains ineligible to run Tasks of this Job until it is reimaged. The Compute Node remains active and can be used for other Jobs. The Job Preparation Task can run multiple times on the same Node. Therefore, you should write the Job Preparation Task to handle re-execution. If the Node is rebooted, the Job Preparation Task is run again on the Compute Node before scheduling any other Task of the Job, if rerunOnNodeRebootAfterSuccess is true or if the Job Preparation Task did not previously complete. If the Node is reimaged, the Job Preparation Task is run again before scheduling any Task of the Job. Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. — shape: {commandLine: string, constraints?: any, containerSettings?: any, environmentSettings?: list, id?: string, rerunOnNodeRebootAfterSuccess?: bool, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
  --jobReleaseTask: any # The Job Release Task runs when the Job ends, because of one of the following: The user calls the Terminate Job API, or the Delete Job API while the Job is still active, the Job's maximum wall clock time constraint is reached, and the Job is still active, or the Job's Job Manager Task completed, and the Job is configured to terminate when the Job Manager completes. The Job Release Task runs on each Node where Tasks of the Job have run and the Job Preparation Task ran and completed. If you reimage a Node after it has run the Job Preparation Task, and the Job ends without any further Tasks of the Job running on that Node (and hence the Job Preparation Task does not re-run), then the Job Release Task does not run on that Compute Node. If a Node reboots while the Job Release Task is still running, the Job Release Task runs again when the Compute Node starts up. The Job is not marked as complete until all Job Release Tasks have completed. The Job Release Task runs in the background. It does not occupy a scheduling slot; that is, it does not count towards the maxTasksPerNode limit specified on the Pool. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, id?: string, maxWallClockTime?: string, resourceFiles?: list, retentionTime?: string, userIdentity?: any}
  --metadata: list # The Batch service does not assign any meaning to metadata; it is solely for the use of user code. — item shape: {name: string, value: string}
  --networkConfiguration: any # shape: {subnetId: string}
  --onAllTasksComplete: string@onAllTasksComplete-completer
  --onTaskFailure: string@onTaskFailure-completer # A Task is considered to have failed if has a failureInfo. A failureInfo is set if the Task completes with a non-zero exit code after exhausting its retry count, or if there was an error starting the Task, for example due to a resource file download error. The default is noaction.
  poolInfo: any # shape: {autoPoolSpecification?: any, poolId?: string}
  --priority: int # Priority values can range from -1000 to 1000, with -1000 being the lowest priority and 1000 being the highest priority. The default value is 0. (format: int32)
  --usesTaskDependencies: string@bool-completer
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobs" $qp)
  let body = {commonEnvironmentSettings: $commonEnvironmentSettings, constraints: $constraints, displayName: $displayName, id: $id, jobManagerTask: $jobManagerTask, jobPreparationTask: $jobPreparationTask, jobReleaseTask: $jobReleaseTask, metadata: $metadata, networkConfiguration: $networkConfiguration, onAllTasksComplete: $onAllTasksComplete, onTaskFailure: $onTaskFailure, poolInfo: $poolInfo, priority: $priority, usesTaskDependencies: $usesTaskDependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a Job.
#
# DELETE /jobs/{jobId}
# operationId: Job_Delete
export def "jobs Delete" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified Job.
#
# GET /jobs/{jobId}
# operationId: Job_Get
export def "jobs Get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<commonEnvironmentSettings: table<name: string, value: string>, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string>, creationTime: string, displayName: string, eTag: string, executionInfo: record<endTime: string, poolId: string, schedulingError: record<category: string, code: string, details: list, message: string>, startTime: string, terminateReason: string>, id: string, jobManagerTask: record<allowLowPriorityNode: bool, applicationPackageReferences: list<record>, authenticationTokenSettings: record<access: list>, commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, displayName: string, environmentSettings: list<record>, id: string, killJobOnCompletion: bool, outputFiles: list<record>, resourceFiles: list<record>, runExclusive: bool, userIdentity: record<autoUser: record, username: string>>, jobPreparationTask: record<commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, id: string, rerunOnNodeRebootAfterSuccess: bool, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, jobReleaseTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, id: string, maxWallClockTime: string, resourceFiles: list<record>, retentionTime: string, userIdentity: record<autoUser: record, username: string>>, lastModified: string, metadata: table<name: string, value: string>, networkConfiguration: record<subnetId: string>, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record<autoPoolSpecification: record<autoPoolIdPrefix: string, keepAlive: bool, pool: record, poolLifetimeOption: string>, poolId: string>, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string, usesTaskDependencies: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the properties of the specified Job.
#
# PATCH /jobs/{jobId}
# operationId: Job_Patch
# --constraints shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
# --metadata item shape: {name: string, value: string}
# --poolInfo shape: {autoPoolSpecification?: any, poolId?: string}
export def "jobs Patch" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
  --metadata: list # If omitted, the existing Job metadata is left unchanged. — item shape: {name: string, value: string}
  --onAllTasksComplete: string@onAllTasksComplete-completer
  --poolInfo: any # shape: {autoPoolSpecification?: any, poolId?: string}
  --priority: int # Priority values can range from -1000 to 1000, with -1000 being the lowest priority and 1000 being the highest priority. If omitted, the priority of the Job is left unchanged. (format: int32)
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)" $qp)
  let body = {constraints: $constraints, metadata: $metadata, onAllTasksComplete: $onAllTasksComplete, poolInfo: $poolInfo, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the properties of the specified Job.
#
# PUT /jobs/{jobId}
# operationId: Job_Update
# --constraints shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
# --metadata item shape: {name: string, value: string}
# --poolInfo shape: {autoPoolSpecification?: any, poolId?: string}
export def "jobs Update" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
  --metadata: list # If omitted, it takes the default value of an empty list; in effect, any existing metadata is deleted. — item shape: {name: string, value: string}
  --onAllTasksComplete: string@onAllTasksComplete-completer
  poolInfo: any # shape: {autoPoolSpecification?: any, poolId?: string}
  --priority: int # Priority values can range from -1000 to 1000, with -1000 being the lowest priority and 1000 being the highest priority. If omitted, it is set to the default value 0. (format: int32)
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)" $qp)
  let body = {constraints: $constraints, metadata: $metadata, onAllTasksComplete: $onAllTasksComplete, poolInfo: $poolInfo, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a collection of Tasks to the specified Job.
#
# POST /jobs/{jobId}/addtaskcollection
# operationId: Task_AddCollection
# --value item shape: {affinityInfo?: any, applicationPackageReferences?: list, authenticationTokenSettings?: any, commandLine: string, constraints?: any, containerSettings?: any, dependsOn?: any, displayName?: string, environmentSettings?: list, exitConditions?: any, id: string, multiInstanceSettings?: any, outputFiles?: list, resourceFiles?: list, userIdentity?: any}
export def "jobs-addtaskcollection AddCollection" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  value: list # The total serialized size of this collection must be less than 1MB. If it is greater than 1MB (for example if each Task has 100's of resource files or environment variables), the request will fail with code 'RequestBodyTooLarge' and should be retried again with fewer Tasks. — item shape: {affinityInfo?: any, applicationPackageReferences?: list, authenticationTokenSettings?: any, commandLine: string, constraints?: any, containerSettings?: any, dependsOn?: any, displayName?: string, environmentSettings?: list, exitConditions?: any, id: string, multiInstanceSettings?: any, outputFiles?: list, resourceFiles?: list, userIdentity?: any}
]: any -> record<value: table<eTag: string, error: record, lastModified: string, location: string, status: string, taskId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/addtaskcollection" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disables the specified Job, preventing new Tasks from running.
#
# POST /jobs/{jobId}/disable
# operationId: Job_Disable
export def "jobs-disable Disable" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  disableTasks: string@disableTasks-completer
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/disable" $qp)
  let body = {disableTasks: $disableTasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enables the specified Job, allowing new Tasks to run.
#
# POST /jobs/{jobId}/enable
# operationId: Job_Enable
export def "jobs-enable Enable" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/enable" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the execution status of the Job Preparation and Job Release Task for the specified Job across the Compute Nodes where the Job has run.
#
# GET /jobs/{jobId}/jobpreparationandreleasetaskstatus
# operationId: Job_ListPreparationAndReleaseTaskStatus
export def "jobs-jobpreparationandreleasetaskstatus ListPreparationAndReleaseTaskStatus" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-job-preparation-and-release-status.
  --select: string # An OData $select clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Tasks can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<jobPreparationTaskExecutionInfo: record, jobReleaseTaskExecutionInfo: record, nodeId: string, nodeUrl: string, poolId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/jobpreparationandreleasetaskstatus" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Task counts for the specified Job.
#
# GET /jobs/{jobId}/taskcounts
# operationId: Job_GetTaskCounts
export def "jobs-taskcounts GetTaskCounts" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<active: int, completed: int, failed: int, running: int, succeeded: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/taskcounts" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all of the Tasks that are associated with the specified Job.
#
# GET /jobs/{jobId}/tasks
# operationId: Task_List
export def "jobs-tasks List" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-tasks.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Tasks can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<affinityInfo: record, applicationPackageReferences: list, authenticationTokenSettings: record, commandLine: string, constraints: record, containerSettings: record, creationTime: string, dependsOn: record, displayName: string, eTag: string, environmentSettings: list, executionInfo: record, exitConditions: record, id: string, lastModified: string, multiInstanceSettings: record, nodeInfo: record, outputFiles: list, previousState: string, previousStateTransitionTime: string, resourceFiles: list, state: string, stateTransitionTime: string, stats: record, url: string, userIdentity: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a Task to the specified Job.
#
# POST /jobs/{jobId}/tasks
# operationId: Task_Add
# --affinityInfo shape: {affinityId: string}
# --applicationPackageReferences item shape: {applicationId: string, version?: string}
# --authenticationTokenSettings shape: {access?: list}
# --constraints shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
# --containerSettings shape: {containerRunOptions?: string, imageName: string, registry?: any, workingDirectory?: "taskWorkingDirectory"|"containerImageDefault"}
# --dependsOn shape: {taskIdRanges?: list, taskIds?: list}
# --environmentSettings item shape: {name: string, value?: string}
# --exitConditions shape: {default?: any, exitCodeRanges?: list, exitCodes?: list, fileUploadError?: any, preProcessingError?: any}
# --multiInstanceSettings shape: {commonResourceFiles?: list, coordinationCommandLine: string, numberOfInstances?: int}
# --outputFiles item shape: {destination: any, filePattern: string, uploadOptions: any}
# --resourceFiles item shape: {autoStorageContainerName?: string, blobPrefix?: string, fileMode?: string, filePath?: string, httpUrl?: string, storageContainerUrl?: string}
# --userIdentity shape: {autoUser?: any, username?: string}
export def "jobs-tasks Add" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --affinityInfo: any # shape: {affinityId: string}
  --applicationPackageReferences: list # Application packages are downloaded and deployed to a shared directory, not the Task working directory. Therefore, if a referenced package is already on the Node, and is up to date, then it is not re-downloaded; the existing copy on the Compute Node is used. If a referenced Package cannot be installed, for example because the package has been deleted or because download failed, the Task fails. — item shape: {applicationId: string, version?: string}
  --authenticationTokenSettings: any # shape: {access?: list}
  commandLine: string # For multi-instance Tasks, the command line is executed as the primary Task, after the primary Task and all subtasks have finished executing the coordination command line. The command line does not run under a shell, and therefore cannot take advantage of shell features such as environment variable expansion. If you want to take advantage of such features, you should invoke the shell in the command line, for example using "cmd /c MyCommand" in Windows or "/bin/sh -c MyCommand" in Linux. If the command line refers to file paths, it should use a relative path (relative to the Task working directory), or use the Batch provided environment variable (https://docs.microsoft.com/en-us/azure/batch/batch-compute-node-environment-variables).
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
  --containerSettings: any # shape: {containerRunOptions?: string, imageName: string, registry?: any, workingDirectory?: "taskWorkingDirectory"|"containerImageDefault"}
  --dependsOn: any # shape: {taskIdRanges?: list, taskIds?: list}
  --displayName: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  --environmentSettings: list # item shape: {name: string, value?: string}
  --exitConditions: any # shape: {default?: any, exitCodeRanges?: list, exitCodes?: list, fileUploadError?: any, preProcessingError?: any}
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two IDs within a Job that differ only by case).
  --multiInstanceSettings: any # Multi-instance Tasks are commonly used to support MPI Tasks. In the MPI case, if any of the subtasks fail (for example due to exiting with a non-zero exit code) the entire multi-instance Task fails. The multi-instance Task is then terminated and retried, up to its retry limit. — shape: {commonResourceFiles?: list, coordinationCommandLine: string, numberOfInstances?: int}
  --outputFiles: list # For multi-instance Tasks, the files will only be uploaded from the Compute Node on which the primary Task is executed. — item shape: {destination: any, filePattern: string, uploadOptions: any}
  --resourceFiles: list # For multi-instance Tasks, the resource files will only be downloaded to the Compute Node on which the primary Task is executed. There is a maximum size for the list of resource files.  When the max size is exceeded, the request will fail and the response error code will be RequestEntityTooLarge. If this occurs, the collection of ResourceFiles must be reduced in size. This can be achieved using .zip files, Application Packages, or Docker Containers. — item shape: {autoStorageContainerName?: string, blobPrefix?: string, fileMode?: string, filePath?: string, httpUrl?: string, storageContainerUrl?: string}
  --userIdentity: any # Specify either the userName or autoUser property, but not both. — shape: {autoUser?: any, username?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks" $qp)
  let body = {affinityInfo: $affinityInfo, applicationPackageReferences: $applicationPackageReferences, authenticationTokenSettings: $authenticationTokenSettings, commandLine: $commandLine, constraints: $constraints, containerSettings: $containerSettings, dependsOn: $dependsOn, displayName: $displayName, environmentSettings: $environmentSettings, exitConditions: $exitConditions, id: $id, multiInstanceSettings: $multiInstanceSettings, outputFiles: $outputFiles, resourceFiles: $resourceFiles, userIdentity: $userIdentity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a Task from the specified Job.
#
# DELETE /jobs/{jobId}/tasks/{taskId}
# operationId: Task_Delete
export def "jobs-tasks Delete" [
  jobId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified Task.
#
# GET /jobs/{jobId}/tasks/{taskId}
# operationId: Task_Get
export def "jobs-tasks Get" [
  jobId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<affinityInfo: record<affinityId: string>, applicationPackageReferences: table<applicationId: string, version: string>, authenticationTokenSettings: record<access: list<string>>, commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record<password: string, registryServer: string, username: string>, workingDirectory: string>, creationTime: string, dependsOn: record<taskIdRanges: list<record>, taskIds: list<string>>, displayName: string, eTag: string, environmentSettings: table<name: string, value: string>, executionInfo: record<containerInfo: record<containerId: string, error: string, state: string>, endTime: string, exitCode: int, failureInfo: record<category: string, code: string, details: list, message: string>, lastRequeueTime: string, lastRetryTime: string, requeueCount: int, result: string, retryCount: int, startTime: string>, exitConditions: record<default: record<dependencyAction: string, jobAction: string>, exitCodeRanges: list<record>, exitCodes: list<record>, fileUploadError: record<dependencyAction: string, jobAction: string>, preProcessingError: record<dependencyAction: string, jobAction: string>>, id: string, lastModified: string, multiInstanceSettings: record<commonResourceFiles: list<record>, coordinationCommandLine: string, numberOfInstances: int>, nodeInfo: record<affinityId: string, nodeId: string, nodeUrl: string, poolId: string, taskRootDirectory: string, taskRootDirectoryUrl: string>, outputFiles: table<destination: record, filePattern: string, uploadOptions: record>, previousState: string, previousStateTransitionTime: string, resourceFiles: table<autoStorageContainerName: string, blobPrefix: string, fileMode: string, filePath: string, httpUrl: string, storageContainerUrl: string>, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string, userIdentity: record<autoUser: record<elevationLevel: string, scope: string>, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the properties of the specified Task.
#
# PUT /jobs/{jobId}/tasks/{taskId}
# operationId: Task_Update
# --constraints shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
export def "jobs-tasks Update" [
  jobId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)" $qp)
  let body = {constraints: $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the files in a Task's directory on its Compute Node.
#
# GET /jobs/{jobId}/tasks/{taskId}/files
# operationId: File_ListFromTask
export def "jobs-tasks-files ListFromTask" [
  jobId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-task-files.
  --recursive: string@bool-completer # Whether to list children of the Task directory. This parameter can be used in combination with the filter parameter to list specific type of files.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<isDirectory: bool, name: string, properties: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "recursive" $recursive "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)/files" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the specified Task file from the Compute Node where the Task ran.
#
# DELETE /jobs/{jobId}/tasks/{taskId}/files/{filePath}
# operationId: File_DeleteFromTask
export def "jobs-tasks-files DeleteFromTask" [
  jobId: string
  taskId: string
  filePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recursive: string@bool-completer # Whether to delete children of a directory. If the filePath parameter represents a directory instead of a file, you can set recursive to true to delete the directory and all of the files and subdirectories in it. If recursive is false then the directory must be empty or deletion will fail.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recursive" $recursive "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)/files/($filePath)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the content of the specified Task file.
#
# GET /jobs/{jobId}/tasks/{taskId}/files/{filePath}
# operationId: File_GetFromTask
export def "jobs-tasks-files GetFromTask" [
  jobId: string
  taskId: string
  filePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --ocp-range: string # The byte range to be retrieved. The default is to retrieve the entire file. The format is bytes=startRange-endRange.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)/files/($filePath)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "ocp-range": $ocp_range, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the properties of the specified Task file.
#
# HEAD /jobs/{jobId}/tasks/{taskId}/files/{filePath}
# operationId: File_GetPropertiesFromTask
export def "jobs-tasks-files GetPropertiesFromTask" [
  jobId: string
  taskId: string
  filePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)/files/($filePath)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reactivates a Task, allowing it to run again even if its retry count has been exhausted.
#
# POST /jobs/{jobId}/tasks/{taskId}/reactivate
# operationId: Task_Reactivate
export def "jobs-tasks-reactivate Reactivate" [
  jobId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)/reactivate" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all of the subtasks that are associated with the specified multi-instance Task.
#
# GET /jobs/{jobId}/tasks/{taskId}/subtasksinfo
# operationId: Task_ListSubtasks
export def "jobs-tasks-subtasksinfo ListSubtasks" [
  jobId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # An OData $select clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<value: table<containerInfo: record, endTime: string, exitCode: int, failureInfo: record, id: int, nodeInfo: record, previousState: string, previousStateTransitionTime: string, result: string, startTime: string, state: string, stateTransitionTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)/subtasksinfo" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terminates the specified Task.
#
# POST /jobs/{jobId}/tasks/{taskId}/terminate
# operationId: Task_Terminate
export def "jobs-tasks-terminate Terminate" [
  jobId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/tasks/($taskId)/terminate" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terminates the specified Job, marking it as completed.
#
# POST /jobs/{jobId}/terminate
# operationId: Job_Terminate
export def "jobs-terminate Terminate" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --terminateReason: string
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($jobId)/terminate" $qp)
  let body = {terminateReason: $terminateReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all of the Job Schedules in the specified Account.
#
# GET /jobschedules
# operationId: JobSchedule_List
export def "jobschedules List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-job-schedules.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Job Schedules can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobSpecification: record, lastModified: string, metadata: list, previousState: string, previousStateTransitionTime: string, schedule: record, state: string, stateTransitionTime: string, stats: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobschedules" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a Job Schedule to the specified Account.
#
# POST /jobschedules
# operationId: JobSchedule_Add
# --jobSpecification shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
# --metadata item shape: {name: string, value: string}
# --schedule shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
export def "jobschedules Add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --displayName: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two IDs within an Account that differ only by case).
  jobSpecification: any # shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
  --metadata: list # The Batch service does not assign any meaning to metadata; it is solely for the use of user code. — item shape: {name: string, value: string}
  schedule: any # shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobschedules" $qp)
  let body = {displayName: $displayName, id: $id, jobSpecification: $jobSpecification, metadata: $metadata, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a Job Schedule from the specified Account.
#
# DELETE /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Delete
export def "jobschedules Delete" [
  jobScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobschedules/($jobScheduleId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified Job Schedule.
#
# GET /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Get
export def "jobschedules Get" [
  jobScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<creationTime: string, displayName: string, eTag: string, executionInfo: record<endTime: string, nextRunTime: string, recentJob: record<id: string, url: string>>, id: string, jobSpecification: record<commonEnvironmentSettings: list<record>, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string>, displayName: string, jobManagerTask: record<allowLowPriorityNode: bool, applicationPackageReferences: list, authenticationTokenSettings: record, commandLine: string, constraints: record, containerSettings: record, displayName: string, environmentSettings: list, id: string, killJobOnCompletion: bool, outputFiles: list, resourceFiles: list, runExclusive: bool, userIdentity: record>, jobPreparationTask: record<commandLine: string, constraints: record, containerSettings: record, environmentSettings: list, id: string, rerunOnNodeRebootAfterSuccess: bool, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, jobReleaseTask: record<commandLine: string, containerSettings: record, environmentSettings: list, id: string, maxWallClockTime: string, resourceFiles: list, retentionTime: string, userIdentity: record>, metadata: list<record>, networkConfiguration: record<subnetId: string>, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record<autoPoolSpecification: record, poolId: string>, priority: int, usesTaskDependencies: bool>, lastModified: string, metadata: table<name: string, value: string>, previousState: string, previousStateTransitionTime: string, schedule: record<doNotRunAfter: string, doNotRunUntil: string, recurrenceInterval: string, startWindow: string>, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobschedules/($jobScheduleId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Checks the specified Job Schedule exists.
#
# HEAD /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Exists
export def "jobschedules Exists" [
  jobScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobschedules/($jobScheduleId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the properties of the specified Job Schedule.
#
# PATCH /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Patch
# --jobSpecification shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
# --metadata item shape: {name: string, value: string}
# --schedule shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
export def "jobschedules Patch" [
  jobScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --jobSpecification: any # shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
  --metadata: list # If you do not specify this element, existing metadata is left unchanged. — item shape: {name: string, value: string}
  --schedule: any # shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobschedules/($jobScheduleId)" $qp)
  let body = {jobSpecification: $jobSpecification, metadata: $metadata, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the properties of the specified Job Schedule.
#
# PUT /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Update
# --jobSpecification shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
# --metadata item shape: {name: string, value: string}
# --schedule shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
export def "jobschedules Update" [
  jobScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  jobSpecification: any # shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
  --metadata: list # If you do not specify this element, it takes the default value of an empty list; in effect, any existing metadata is deleted. — item shape: {name: string, value: string}
  schedule: any # shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobschedules/($jobScheduleId)" $qp)
  let body = {jobSpecification: $jobSpecification, metadata: $metadata, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disables a Job Schedule.
#
# POST /jobschedules/{jobScheduleId}/disable
# operationId: JobSchedule_Disable
export def "jobschedules-disable Disable" [
  jobScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobschedules/($jobScheduleId)/disable" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enables a Job Schedule.
#
# POST /jobschedules/{jobScheduleId}/enable
# operationId: JobSchedule_Enable
export def "jobschedules-enable Enable" [
  jobScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobschedules/($jobScheduleId)/enable" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the Jobs that have been created under the specified Job Schedule.
#
# GET /jobschedules/{jobScheduleId}/jobs
# operationId: Job_ListFromJobSchedule
export def "jobschedules-jobs ListFromJobSchedule" [
  jobScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-jobs-in-a-job-schedule.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Jobs can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<commonEnvironmentSettings: list, constraints: record, creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobManagerTask: record, jobPreparationTask: record, jobReleaseTask: record, lastModified: string, metadata: list, networkConfiguration: record, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record, url: string, usesTaskDependencies: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobschedules/($jobScheduleId)/jobs" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terminates a Job Schedule.
#
# POST /jobschedules/{jobScheduleId}/terminate
# operationId: JobSchedule_Terminate
export def "jobschedules-terminate Terminate" [
  jobScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobschedules/($jobScheduleId)/terminate" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets lifetime summary statistics for all of the Jobs in the specified Account.
#
# GET /lifetimejobstats
# operationId: Job_GetAllLifetimeStatistics
export def "lifetimejobstats GetAllLifetimeStatistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lifetimejobstats" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets lifetime summary statistics for all of the Pools in the specified Account.
#
# GET /lifetimepoolstats
# operationId: Pool_GetAllLifetimeStatistics
export def "lifetimepoolstats GetAllLifetimeStatistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<lastUpdateTime: string, resourceStats: record<avgCPUPercentage: float, avgDiskGiB: float, avgMemoryGiB: float, diskReadGiB: float, diskReadIOps: int, diskWriteGiB: float, diskWriteIOps: int, lastUpdateTime: string, networkReadGiB: float, networkWriteGiB: float, peakDiskGiB: float, peakMemoryGiB: float, startTime: string>, startTime: string, url: string, usageStats: record<dedicatedCoreTime: string, lastUpdateTime: string, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lifetimepoolstats" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the number of Compute Nodes in each state, grouped by Pool.
#
# GET /nodecounts
# operationId: Account_ListPoolNodeCounts
export def "nodecounts ListPoolNodeCounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch.
  --maxresults: int # The maximum number of items to return in the response. (format: int32, default: 10)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<dedicated: record, lowPriority: record, poolId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodecounts" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all of the Pools in the specified Account.
#
# GET /pools
# operationId: Pool_List
export def "pools List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-pools.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Pools can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list, applicationPackageReferences: list, autoScaleEvaluationInterval: string, autoScaleFormula: string, autoScaleRun: record, certificateReferences: list, cloudServiceConfiguration: record, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, displayName: string, eTag: string, enableAutoScale: bool, enableInterNodeCommunication: bool, id: string, lastModified: string, maxTasksPerNode: int, metadata: list, mountConfiguration: list, networkConfiguration: record, resizeErrors: list, resizeTimeout: string, startTask: record, state: string, stateTransitionTime: string, stats: record, targetDedicatedNodes: int, targetLowPriorityNodes: int, taskSchedulingPolicy: record, url: string, userAccounts: list, virtualMachineConfiguration: record, vmSize: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pools" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a Pool to the specified Account.
#
# POST /pools
# operationId: Pool_Add
# --applicationPackageReferences item shape: {applicationId: string, version?: string}
# --certificateReferences item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list}
# --cloudServiceConfiguration shape: {osFamily: string, osVersion?: string}
# --metadata item shape: {name: string, value: string}
# --mountConfiguration item shape: {azureBlobFileSystemConfiguration?: any, azureFileShareConfiguration?: any, cifsMountConfiguration?: any, nfsMountConfiguration?: any}
# --networkConfiguration shape: {dynamicVNetAssignmentScope?: "none"|"job", endpointConfiguration?: any, publicIPs?: list, subnetId?: string}
# --startTask shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
# --taskSchedulingPolicy shape: {nodeFillType: "spread"|"pack"}
# --userAccounts item shape: {elevationLevel?: "nonadmin"|"admin", linuxUserConfiguration?: any, name: string, password: string, windowsUserConfiguration?: any}
# --virtualMachineConfiguration shape: {containerConfiguration?: any, dataDisks?: list, imageReference: any, licenseType?: string, nodeAgentSKUId: string, windowsConfiguration?: any}
export def "pools Add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --applicationLicenses: list # The list of application licenses must be a subset of available Batch service application licenses. If a license is requested which is not supported, Pool creation will fail.
  --applicationPackageReferences: list # Changes to Package references affect all new Nodes joining the Pool, but do not affect Compute Nodes that are already in the Pool until they are rebooted or reimaged. There is a maximum of 10 Package references on any given Pool. — item shape: {applicationId: string, version?: string}
  --autoScaleEvaluationInterval: string # The default value is 15 minutes. The minimum and maximum value are 5 minutes and 168 hours respectively. If you specify a value less than 5 minutes or greater than 168 hours, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
  --autoScaleFormula: string # This property must not be specified if enableAutoScale is set to false. It is required if enableAutoScale is set to true. The formula is checked for validity before the Pool is created. If the formula is not valid, the Batch service rejects the request with detailed error information. For more information about specifying this formula, see 'Automatically scale Compute Nodes in an Azure Batch Pool' (https://azure.microsoft.com/documentation/articles/batch-automatic-scaling/).
  --certificateReferences: list # For Windows Nodes, the Batch service installs the Certificates to the specified Certificate store and location. For Linux Compute Nodes, the Certificates are stored in a directory inside the Task working directory and an environment variable AZ_BATCH_CERTIFICATES_DIR is supplied to the Task to query for this location. For Certificates with visibility of 'remoteUser', a 'certs' directory is created in the user's home directory (e.g., /home/{user-name}/certs) and Certificates are placed in that directory. — item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list}
  --cloudServiceConfiguration: any # shape: {osFamily: string, osVersion?: string}
  --displayName: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  --enableAutoScale: string@bool-completer # If false, at least one of targetDedicateNodes and targetLowPriorityNodes must be specified. If true, the autoScaleFormula property is required and the Pool automatically resizes according to the formula. The default value is false.
  --enableInterNodeCommunication: string@bool-completer # Enabling inter-node communication limits the maximum size of the Pool due to deployment restrictions on the Compute Nodes of the Pool. This may result in the Pool not reaching its desired size. The default value is false.
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two Pool IDs within an Account that differ only by case).
  --maxTasksPerNode: int # The default value is 1. The maximum value is the smaller of 4 times the number of cores of the vmSize of the Pool or 256. (format: int32)
  --metadata: list # The Batch service does not assign any meaning to metadata; it is solely for the use of user code. — item shape: {name: string, value: string}
  --mountConfiguration: list # Mount the storage using Azure fileshare, NFS, CIFS or Blobfuse based file system. — item shape: {azureBlobFileSystemConfiguration?: any, azureFileShareConfiguration?: any, cifsMountConfiguration?: any, nfsMountConfiguration?: any}
  --networkConfiguration: any # The network configuration for a Pool. — shape: {dynamicVNetAssignmentScope?: "none"|"job", endpointConfiguration?: any, publicIPs?: list, subnetId?: string}
  --resizeTimeout: string # This timeout applies only to manual scaling; it has no effect when enableAutoScale is set to true. The default value is 15 minutes. The minimum value is 5 minutes. If you specify a value less than 5 minutes, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
  --startTask: any # Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. In some cases the StartTask may be re-run even though the Compute Node was not rebooted. Special care should be taken to avoid StartTasks which create breakaway process or install/launch services from the StartTask working directory, as this will block Batch from being able to re-run the StartTask. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
  --targetDedicatedNodes: int # This property must not be specified if enableAutoScale is set to true. If enableAutoScale is set to false, then you must set either targetDedicatedNodes, targetLowPriorityNodes, or both. (format: int32)
  --targetLowPriorityNodes: int # This property must not be specified if enableAutoScale is set to true. If enableAutoScale is set to false, then you must set either targetDedicatedNodes, targetLowPriorityNodes, or both. (format: int32)
  --taskSchedulingPolicy: any # shape: {nodeFillType: "spread"|"pack"}
  --userAccounts: list # item shape: {elevationLevel?: "nonadmin"|"admin", linuxUserConfiguration?: any, name: string, password: string, windowsUserConfiguration?: any}
  --virtualMachineConfiguration: any # shape: {containerConfiguration?: any, dataDisks?: list, imageReference: any, licenseType?: string, nodeAgentSKUId: string, windowsConfiguration?: any}
  vmSize: string # For information about available sizes of virtual machines for Cloud Services Pools (pools created with cloudServiceConfiguration), see Sizes for Cloud Services (https://azure.microsoft.com/documentation/articles/cloud-services-sizes-specs/). Batch supports all Cloud Services VM sizes except ExtraSmall, A1V2 and A2V2. For information about available VM sizes for Pools using Images from the Virtual Machines Marketplace (pools created with virtualMachineConfiguration) see Sizes for Virtual Machines (Linux) (https://azure.microsoft.com/documentation/articles/virtual-machines-linux-sizes/) or Sizes for Virtual Machines (Windows) (https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/). Batch supports all Azure VM sizes except STANDARD_A0 and those with premium storage (STANDARD_GS, STANDARD_DS, and STANDARD_DSV2 series).
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pools" $qp)
  let body = {applicationLicenses: $applicationLicenses, applicationPackageReferences: $applicationPackageReferences, autoScaleEvaluationInterval: $autoScaleEvaluationInterval, autoScaleFormula: $autoScaleFormula, certificateReferences: $certificateReferences, cloudServiceConfiguration: $cloudServiceConfiguration, displayName: $displayName, enableAutoScale: $enableAutoScale, enableInterNodeCommunication: $enableInterNodeCommunication, id: $id, maxTasksPerNode: $maxTasksPerNode, metadata: $metadata, mountConfiguration: $mountConfiguration, networkConfiguration: $networkConfiguration, resizeTimeout: $resizeTimeout, startTask: $startTask, targetDedicatedNodes: $targetDedicatedNodes, targetLowPriorityNodes: $targetLowPriorityNodes, taskSchedulingPolicy: $taskSchedulingPolicy, userAccounts: $userAccounts, virtualMachineConfiguration: $virtualMachineConfiguration, vmSize: $vmSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a Pool from the specified Account.
#
# DELETE /pools/{poolId}
# operationId: Pool_Delete
export def "pools Delete" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified Pool.
#
# GET /pools/{poolId}
# operationId: Pool_Get
export def "pools Get" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackageReferences: table<applicationId: string, version: string>, autoScaleEvaluationInterval: string, autoScaleFormula: string, autoScaleRun: record<error: record<code: string, message: string, values: list>, results: string, timestamp: string>, certificateReferences: table<storeLocation: string, storeName: string, thumbprint: string, thumbprintAlgorithm: string, visibility: list>, cloudServiceConfiguration: record<osFamily: string, osVersion: string>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, displayName: string, eTag: string, enableAutoScale: bool, enableInterNodeCommunication: bool, id: string, lastModified: string, maxTasksPerNode: int, metadata: table<name: string, value: string>, mountConfiguration: table<azureBlobFileSystemConfiguration: record, azureFileShareConfiguration: record, cifsMountConfiguration: record, nfsMountConfiguration: record>, networkConfiguration: record<dynamicVNetAssignmentScope: string, endpointConfiguration: record<inboundNATPools: list>, publicIPs: list<string>, subnetId: string>, resizeErrors: table<code: string, message: string, values: list>, resizeTimeout: string, startTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, maxTaskRetryCount: int, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, state: string, stateTransitionTime: string, stats: record<lastUpdateTime: string, resourceStats: record<avgCPUPercentage: float, avgDiskGiB: float, avgMemoryGiB: float, diskReadGiB: float, diskReadIOps: int, diskWriteGiB: float, diskWriteIOps: int, lastUpdateTime: string, networkReadGiB: float, networkWriteGiB: float, peakDiskGiB: float, peakMemoryGiB: float, startTime: string>, startTime: string, url: string, usageStats: record<dedicatedCoreTime: string, lastUpdateTime: string, startTime: string>>, targetDedicatedNodes: int, targetLowPriorityNodes: int, taskSchedulingPolicy: record<nodeFillType: string>, url: string, userAccounts: table<elevationLevel: string, linuxUserConfiguration: record, name: string, password: string, windowsUserConfiguration: record>, virtualMachineConfiguration: record<containerConfiguration: record<containerImageNames: list, containerRegistries: list, type: string>, dataDisks: list<record>, imageReference: record<offer: string, publisher: string, sku: string, version: string, virtualMachineImageId: string>, licenseType: string, nodeAgentSKUId: string, windowsConfiguration: record<enableAutomaticUpdates: bool>>, vmSize: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets basic properties of a Pool.
#
# HEAD /pools/{poolId}
# operationId: Pool_Exists
export def "pools Exists" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the properties of the specified Pool.
#
# PATCH /pools/{poolId}
# operationId: Pool_Patch
# --applicationPackageReferences item shape: {applicationId: string, version?: string}
# --certificateReferences item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list}
# --metadata item shape: {name: string, value: string}
# --startTask shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
export def "pools Patch" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --applicationPackageReferences: list # Changes to Package references affect all new Nodes joining the Pool, but do not affect Compute Nodes that are already in the Pool until they are rebooted or reimaged. If this element is present, it replaces any existing Package references. If you specify an empty collection, then all Package references are removed from the Pool. If omitted, any existing Package references are left unchanged. — item shape: {applicationId: string, version?: string}
  --certificateReferences: list # If this element is present, it replaces any existing Certificate references configured on the Pool. If omitted, any existing Certificate references are left unchanged. For Windows Nodes, the Batch service installs the Certificates to the specified Certificate store and location. For Linux Compute Nodes, the Certificates are stored in a directory inside the Task working directory and an environment variable AZ_BATCH_CERTIFICATES_DIR is supplied to the Task to query for this location. For Certificates with visibility of 'remoteUser', a 'certs' directory is created in the user's home directory (e.g., /home/{user-name}/certs) and Certificates are placed in that directory. — item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list}
  --metadata: list # If this element is present, it replaces any existing metadata configured on the Pool. If you specify an empty collection, any metadata is removed from the Pool. If omitted, any existing metadata is left unchanged. — item shape: {name: string, value: string}
  --startTask: any # Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. In some cases the StartTask may be re-run even though the Compute Node was not rebooted. Special care should be taken to avoid StartTasks which create breakaway process or install/launch services from the StartTask working directory, as this will block Batch from being able to re-run the StartTask. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)" $qp)
  let body = {applicationPackageReferences: $applicationPackageReferences, certificateReferences: $certificateReferences, metadata: $metadata, startTask: $startTask} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disables automatic scaling for a Pool.
#
# POST /pools/{poolId}/disableautoscale
# operationId: Pool_DisableAutoScale
export def "pools-disableautoscale DisableAutoScale" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/disableautoscale" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enables automatic scaling for a Pool.
#
# POST /pools/{poolId}/enableautoscale
# operationId: Pool_EnableAutoScale
export def "pools-enableautoscale EnableAutoScale" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --autoScaleEvaluationInterval: string # The default value is 15 minutes. The minimum and maximum value are 5 minutes and 168 hours respectively. If you specify a value less than 5 minutes or greater than 168 hours, the Batch service rejects the request with an invalid property value error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). If you specify a new interval, then the existing autoscale evaluation schedule will be stopped and a new autoscale evaluation schedule will be started, with its starting time being the time when this request was issued. (format: duration)
  --autoScaleFormula: string # The formula is checked for validity before it is applied to the Pool. If the formula is not valid, the Batch service rejects the request with detailed error information. For more information about specifying this formula, see Automatically scale Compute Nodes in an Azure Batch Pool (https://azure.microsoft.com/en-us/documentation/articles/batch-automatic-scaling).
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/enableautoscale" $qp)
  let body = {autoScaleEvaluationInterval: $autoScaleEvaluationInterval, autoScaleFormula: $autoScaleFormula} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the result of evaluating an automatic scaling formula on the Pool.
#
# POST /pools/{poolId}/evaluateautoscale
# operationId: Pool_EvaluateAutoScale
export def "pools-evaluateautoscale EvaluateAutoScale" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  autoScaleFormula: string # The formula is validated and its results calculated, but it is not applied to the Pool. To apply the formula to the Pool, 'Enable automatic scaling on a Pool'. For more information about specifying this formula, see Automatically scale Compute Nodes in an Azure Batch Pool (https://azure.microsoft.com/en-us/documentation/articles/batch-automatic-scaling).
]: any -> record<error: record<code: string, message: string, values: list<record>>, results: string, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/evaluateautoscale" $qp)
  let body = {autoScaleFormula: $autoScaleFormula} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the Compute Nodes in the specified Pool.
#
# GET /pools/{poolId}/nodes
# operationId: ComputeNode_List
export def "pools-nodes List" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-nodes-in-a-pool.
  --select: string # An OData $select clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Compute Nodes can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<affinityId: string, allocationTime: string, certificateReferences: list, endpointConfiguration: record, errors: list, id: string, ipAddress: string, isDedicated: bool, lastBootTime: string, nodeAgentInfo: record, recentTasks: list, runningTasksCount: int, schedulingState: string, startTask: record, startTaskInfo: record, state: string, stateTransitionTime: string, totalTasksRun: int, totalTasksSucceeded: int, url: string, vmSize: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}
# operationId: ComputeNode_Get
export def "pools-nodes Get" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # An OData $select clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<affinityId: string, allocationTime: string, certificateReferences: table<storeLocation: string, storeName: string, thumbprint: string, thumbprintAlgorithm: string, visibility: list>, endpointConfiguration: record<inboundEndpoints: list<record>>, errors: table<code: string, errorDetails: list, message: string>, id: string, ipAddress: string, isDedicated: bool, lastBootTime: string, nodeAgentInfo: record<lastUpdateTime: string, version: string>, recentTasks: table<executionInfo: record, jobId: string, subtaskId: int, taskId: string, taskState: string, taskUrl: string>, runningTasksCount: int, schedulingState: string, startTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, maxTaskRetryCount: int, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, startTaskInfo: record<containerInfo: record<containerId: string, error: string, state: string>, endTime: string, exitCode: int, failureInfo: record<category: string, code: string, details: list, message: string>, lastRetryTime: string, result: string, retryCount: int, startTime: string, state: string>, state: string, stateTransitionTime: string, totalTasksRun: int, totalTasksSucceeded: int, url: string, vmSize: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disables Task scheduling on the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/disablescheduling
# operationId: ComputeNode_DisableScheduling
export def "pools-nodes-disablescheduling DisableScheduling" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --nodeDisableSchedulingOption: string@nodeDisableSchedulingOption-completer # The default value is requeue.
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/disablescheduling" $qp)
  let body = {nodeDisableSchedulingOption: $nodeDisableSchedulingOption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enables Task scheduling on the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/enablescheduling
# operationId: ComputeNode_EnableScheduling
export def "pools-nodes-enablescheduling EnableScheduling" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/enablescheduling" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all of the files in Task directories on the specified Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}/files
# operationId: File_ListFromComputeNode
export def "pools-nodes-files ListFromComputeNode" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-compute-node-files.
  --recursive: string@bool-completer # Whether to list children of a directory.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<isDirectory: bool, name: string, properties: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "recursive" $recursive "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/files" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the specified file from the Compute Node.
#
# DELETE /pools/{poolId}/nodes/{nodeId}/files/{filePath}
# operationId: File_DeleteFromComputeNode
export def "pools-nodes-files DeleteFromComputeNode" [
  poolId: string
  nodeId: string
  filePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recursive: string@bool-completer # Whether to delete children of a directory. If the filePath parameter represents a directory instead of a file, you can set recursive to true to delete the directory and all of the files and subdirectories in it. If recursive is false then the directory must be empty or deletion will fail.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recursive" $recursive "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/files/($filePath)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the content of the specified Compute Node file.
#
# GET /pools/{poolId}/nodes/{nodeId}/files/{filePath}
# operationId: File_GetFromComputeNode
export def "pools-nodes-files GetFromComputeNode" [
  poolId: string
  nodeId: string
  filePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --ocp-range: string # The byte range to be retrieved. The default is to retrieve the entire file. The format is bytes=startRange-endRange.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/files/($filePath)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "ocp-range": $ocp_range, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the properties of the specified Compute Node file.
#
# HEAD /pools/{poolId}/nodes/{nodeId}/files/{filePath}
# operationId: File_GetPropertiesFromComputeNode
export def "pools-nodes-files GetPropertiesFromComputeNode" [
  poolId: string
  nodeId: string
  filePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/files/($filePath)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Remote Desktop Protocol file for the specified Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}/rdp
# operationId: ComputeNode_GetRemoteDesktop
export def "pools-nodes-rdp GetRemoteDesktop" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/rdp" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restarts the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/reboot
# operationId: ComputeNode_Reboot
export def "pools-nodes-reboot Reboot" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --nodeRebootOption: string@nodeRebootOption-completer # The default value is requeue.
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/reboot" $qp)
  let body = {nodeRebootOption: $nodeRebootOption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reinstalls the operating system on the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/reimage
# operationId: ComputeNode_Reimage
export def "pools-nodes-reimage Reimage" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --nodeReimageOption: string@nodeReimageOption-completer # The default value is requeue.
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/reimage" $qp)
  let body = {nodeReimageOption: $nodeReimageOption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the settings required for remote login to a Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}/remoteloginsettings
# operationId: ComputeNode_GetRemoteLoginSettings
export def "pools-nodes-remoteloginsettings GetRemoteLoginSettings" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<remoteLoginIPAddress: string, remoteLoginPort: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/remoteloginsettings" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Azure Batch service log files from the specified Compute Node to Azure Blob Storage.
#
# POST /pools/{poolId}/nodes/{nodeId}/uploadbatchservicelogs
# operationId: ComputeNode_UploadBatchServiceLogs
export def "pools-nodes-uploadbatchservicelogs UploadBatchServiceLogs" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  containerUrl: string # The URL must include a Shared Access Signature (SAS) granting write permissions to the container. The SAS duration must allow enough time for the upload to finish. The start time for SAS is optional and recommended to not be specified.
  --endTime: string # Any log file containing a log message in the time range will be uploaded. This means that the operation might retrieve more logs than have been requested since the entire log file is always uploaded, but the operation should not retrieve fewer logs than have been requested. If omitted, the default is to upload all logs available after the startTime. (format: date-time)
  startTime: string # Any log file containing a log message in the time range will be uploaded. This means that the operation might retrieve more logs than have been requested since the entire log file is always uploaded, but the operation should not retrieve fewer logs than have been requested. (format: date-time)
]: any -> record<numberOfFilesUploaded: int, virtualDirectoryName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/uploadbatchservicelogs" $qp)
  let body = {containerUrl: $containerUrl, endTime: $endTime, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a user Account to the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/users
# operationId: ComputeNode_AddUser
export def "pools-nodes-users AddUser" [
  poolId: string
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --expiryTime: string # If omitted, the default is 1 day from the current time. For Linux Compute Nodes, the expiryTime has a precision up to a day. (format: date-time)
  --isAdmin: string@bool-completer # The default value is false.
  name: string
  --password: string # The password is required for Windows Compute Nodes (those created with 'cloudServiceConfiguration', or created with 'virtualMachineConfiguration' using a Windows Image reference). For Linux Compute Nodes, the password can optionally be specified along with the sshPublicKey property.
  --sshPublicKey: string # The public key should be compatible with OpenSSH encoding and should be base 64 encoded. This property can be specified only for Linux Compute Nodes. If this is specified for a Windows Compute Node, then the Batch service rejects the request; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request).
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/users" $qp)
  let body = {expiryTime: $expiryTime, isAdmin: $isAdmin, name: $name, password: $password, sshPublicKey: $sshPublicKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a user Account from the specified Compute Node.
#
# DELETE /pools/{poolId}/nodes/{nodeId}/users/{userName}
# operationId: ComputeNode_DeleteUser
export def "pools-nodes-users DeleteUser" [
  poolId: string
  nodeId: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/users/($userName)" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the password and expiration time of a user Account on the specified Compute Node.
#
# PUT /pools/{poolId}/nodes/{nodeId}/users/{userName}
# operationId: ComputeNode_UpdateUser
export def "pools-nodes-users UpdateUser" [
  poolId: string
  nodeId: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --expiryTime: string # If omitted, the default is 1 day from the current time. For Linux Compute Nodes, the expiryTime has a precision up to a day. (format: date-time)
  --password: string # The password is required for Windows Compute Nodes (those created with 'cloudServiceConfiguration', or created with 'virtualMachineConfiguration' using a Windows Image reference). For Linux Compute Nodes, the password can optionally be specified along with the sshPublicKey property. If omitted, any existing password is removed.
  --sshPublicKey: string # The public key should be compatible with OpenSSH encoding and should be base 64 encoded. This property can be specified only for Linux Compute Nodes. If this is specified for a Windows Compute Node, then the Batch service rejects the request; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). If omitted, any existing SSH public key is removed.
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/nodes/($nodeId)/users/($userName)" $qp)
  let body = {expiryTime: $expiryTime, password: $password, sshPublicKey: $sshPublicKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes Compute Nodes from the specified Pool.
#
# POST /pools/{poolId}/removenodes
# operationId: Pool_RemoveNodes
export def "pools-removenodes RemoveNodes" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --nodeDeallocationOption: string@nodeDeallocationOption-completer # The default value is requeue.
  nodeList: list
  --resizeTimeout: string # The default value is 15 minutes. The minimum value is 5 minutes. If you specify a value less than 5 minutes, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/removenodes" $qp)
  let body = {nodeDeallocationOption: $nodeDeallocationOption, nodeList: $nodeList, resizeTimeout: $resizeTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Changes the number of Compute Nodes that are assigned to a Pool.
#
# POST /pools/{poolId}/resize
# operationId: Pool_Resize
export def "pools-resize Resize" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
  --nodeDeallocationOption: string@nodeDeallocationOption-completer # The default value is requeue.
  --resizeTimeout: string # The default value is 15 minutes. The minimum value is 5 minutes. If you specify a value less than 5 minutes, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
  --targetDedicatedNodes: int # format: int32
  --targetLowPriorityNodes: int # format: int32
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/resize" $qp)
  let body = {nodeDeallocationOption: $nodeDeallocationOption, resizeTimeout: $resizeTimeout, targetDedicatedNodes: $targetDedicatedNodes, targetLowPriorityNodes: $targetLowPriorityNodes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stops an ongoing resize operation on the Pool.
#
# POST /pools/{poolId}/stopresize
# operationId: Pool_StopResize
export def "pools-stopresize StopResize" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  --If-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --If-None-Match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --If-Modified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time.
  --If-Unmodified-Since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time.
]: nothing -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/stopresize" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date, "If-Match": $If_Match, "If-None-Match": $If_None_Match, "If-Modified-Since": $If_Modified_Since, "If-Unmodified-Since": $If_Unmodified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the properties of the specified Pool.
#
# POST /pools/{poolId}/updateproperties
# operationId: Pool_UpdateProperties
# --applicationPackageReferences item shape: {applicationId: string, version?: string}
# --certificateReferences item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list}
# --metadata item shape: {name: string, value: string}
# --startTask shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
export def "pools-updateproperties UpdateProperties" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
  applicationPackageReferences: list # The list replaces any existing Application Package references on the Pool. Changes to Application Package references affect all new Compute Nodes joining the Pool, but do not affect Compute Nodes that are already in the Pool until they are rebooted or reimaged. There is a maximum of 10 Application Package references on any given Pool. If omitted, or if you specify an empty collection, any existing Application Packages references are removed from the Pool. A maximum of 10 references may be specified on a given Pool. — item shape: {applicationId: string, version?: string}
  certificateReferences: list # This list replaces any existing Certificate references configured on the Pool. If you specify an empty collection, any existing Certificate references are removed from the Pool. For Windows Nodes, the Batch service installs the Certificates to the specified Certificate store and location. For Linux Compute Nodes, the Certificates are stored in a directory inside the Task working directory and an environment variable AZ_BATCH_CERTIFICATES_DIR is supplied to the Task to query for this location. For Certificates with visibility of 'remoteUser', a 'certs' directory is created in the user's home directory (e.g., /home/{user-name}/certs) and Certificates are placed in that directory. — item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list}
  metadata: list # This list replaces any existing metadata configured on the Pool. If omitted, or if you specify an empty collection, any existing metadata is removed from the Pool. — item shape: {name: string, value: string}
  --startTask: any # Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. In some cases the StartTask may be re-run even though the Compute Node was not rebooted. Special care should be taken to avoid StartTasks which create breakaway process or install/launch services from the StartTask working directory, as this will block Batch from being able to re-run the StartTask. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
]: any -> record<code: string, message: record<lang: string, value: string>, values: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pools/($poolId)/updateproperties" $qp)
  let body = {applicationPackageReferences: $applicationPackageReferences, certificateReferences: $certificateReferences, metadata: $metadata, startTask: $startTask} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the usage metrics, aggregated by Pool across individual time intervals, for the specified Account.
#
# GET /poolusagemetrics
# operationId: Pool_ListUsageMetrics
export def "poolusagemetrics ListUsageMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starttime: string # The earliest time from which to include metrics. This must be at least two and a half hours before the current time. If not specified this defaults to the start time of the last aggregation interval currently available. (format: date-time)
  --endtime: string # The latest time from which to include metrics. This must be at least two hours before the current time. If not specified this defaults to the end time of the last aggregation interval currently available. (format: date-time)
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-account-usage-metrics.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 results will be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<endTime: string, poolId: string, startTime: string, totalCoreHours: float, vmSize: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starttime" $starttime "scalar") (serialize-qp "endtime" $endtime "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/poolusagemetrics" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all Virtual Machine Images supported by the Azure Batch service.
#
# GET /supportedimages
# operationId: Account_ListSupportedImages
export def "supportedimages ListSupportedImages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-support-images.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 results will be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version.
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0.
  --return-client-request-id: string@bool-completer # Whether the server should return the client-request-id in the response.
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly.
]: nothing -> record<odata_nextLink: string, value: table<batchSupportEndOfLife: string, capabilities: list, imageReference: record, nodeAgentSKUId: string, osType: string, verificationType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/supportedimages" $qp)
  let extra_headers = {"client-request-id": $client_request_id, "return-client-request-id": $return_client_request_id, "ocp-date": $ocp_date} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
