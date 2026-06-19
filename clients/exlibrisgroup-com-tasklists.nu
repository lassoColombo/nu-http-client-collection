# Auto-generated client for Ex Libris APIs v1.0
# Source: https://api.apis.guru/v2/specs/exlibrisgroup.com/tasklists/1.0/openapi.json
# Auth: --token flag or $env.EX_LIBRIS_APIS_TOKEN

const BASE_URL = "https://api-eu.hosted.exlibrisgroup.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EX_LIBRIS_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-apikey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "apikey")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://api-eu.hosted.exlibrisgroup.com" "https://api-na.hosted.exlibrisgroup.com" "https://api-ap.hosted.exlibrisgroup.com" "https://api-cn.hosted.exlibrisgroup.com" "https://api-ca.hosted.exlibrisgroup.com"] }
def auth-scheme-completer [] { ["query-apikey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "almaws-task-lists-printouts get" } } | get name | first)
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

# Retrieve Printouts
#
# GET /almaws/v1/task-lists/printouts
# operationId: get/almaws/v1/task-lists/printouts
export def "almaws-task-lists-printouts get" [
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
  --letter: string # Printout Name. Optional. (default: ALL)
  --status: string # Printout status. Optional. Valid values are: Printed, Pending, Canceled. (default: ALL)
  --printer-id: string # Printout Printer (default: ALL)
  --printout-id: string # A list of Printout IDs (for example: 123,456,778) from 1 to the limit of 100 Optional. Use of this option overrides all of the filtering parameters (default: ALL)
  --limit: int # Limits the number of results. Optional. Valid values are 0-100. Default value: 10. (default: 10)
  --offset: int # Offset of the results returned. Optional. Default value: 0, which means that the first results will be returned. (default: 0)
]: nothing -> record<printout: table<date: string, id: string, letter: string, link: string, printer: record, printout: string, size: string, source: string, status: record>, total_record_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "letter" $letter "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "printer_id" $printer_id "scalar") (serialize-qp "printout_id" $printout_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/printouts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"letter": $letter, "status": $status, "printer_id": $printer_id, "printout_id": $printout_id, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Act on Printouts
#
# POST /almaws/v1/task-lists/printouts
# operationId: post/almaws/v1/task-lists/printouts
export def "almaws-task-lists-printouts create" [
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
  --letter: string # Printout Name. Optional. (default: ALL)
  --status: string # Printout status. Optional. Valid values are: Printed, Pending, Canceled. (default: ALL)
  --printer-id: string # Printout Printer (default: ALL)
  --printout-id: string # A list of Printout IDs (for example: 123,456,778) from 1 to the limit of 100 Optional. Use of this option overrides all of the filtering parameters (default: ALL)
  --op: string # The operation to perform on the printout. Currently, the options are: 'mark_as_printed','mark_as_canceled'
]: nothing -> record<printout: table<date: string, id: string, letter: string, link: string, printer: record, printout: string, size: string, source: string, status: record>, total_record_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "letter" $letter "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "printer_id" $printer_id "scalar") (serialize-qp "printout_id" $printout_id "scalar") (serialize-qp "op" $op "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/printouts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"letter": $letter, "status": $status, "printer_id": $printer_id, "printout_id": $printout_id, "op": $op} | compact), body: null}
}

# Retrieve a Printout
#
# GET /almaws/v1/task-lists/printouts/{printout_id}
# operationId: get/almaws/v1/task-lists/printouts/{printout_id}
export def "almaws-task-lists-printouts get-{printout-id}" [
  printout_id: string
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
]: nothing -> record<date: string, id: string, letter: string, link: string, printer: record<desc: string, value: string>, printout: string, size: string, source: string, status: record<desc: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($printout_id | is-empty) { error make --unspanned { msg: "path parameter 'printout_id' must be non-empty" } }
  let full_url = (build-url $base ({printout_id: (encode-path-segment $printout_id)} | format pattern "/almaws/v1/task-lists/printouts/{printout_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Printout Service
#
# POST /almaws/v1/task-lists/printouts/{printout_id}
# operationId: post/almaws/v1/task-lists/printouts/{printout_id}
export def "almaws-task-lists-printouts create-{printout-id}" [
  printout_id: string
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
  --op: string # The operation to perform on the printout. Currently, the options are 'mark_as_printed','mark_as_canceled'
]: nothing -> record<date: string, id: string, letter: string, link: string, printer: record<desc: string, value: string>, printout: string, size: string, source: string, status: record<desc: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($printout_id | is-empty) { error make --unspanned { msg: "path parameter 'printout_id' must be non-empty" } }
  let qp = [(serialize-qp "op" $op "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({printout_id: (encode-path-segment $printout_id)} | format pattern "/almaws/v1/task-lists/printouts/{printout_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"op": $op} | compact), body: null}
}

# Get Requested Resources
#
# GET /almaws/v1/task-lists/requested-resources
# operationId: get/almaws/v1/task-lists/requested-resources
export def "almaws-task-lists-requested-resources get" [
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
  --library: string # The library of the given circulation desk or department where the resources are located. Mandatory.
  --circ-desk: string # The circulation desk where the action is being performed. Mandatory.
  --location: string # The location code. Optional. (default: )
  --order-by: string # The order in which to retrieve the results: location/call_number (default). (default: call_number)
  --direction: string # The order direction in which to retrieve the results. Optional. (default: asc)
  --pickup-inst: string # The pickup institution. Optional. (default: )
  --reported: string # Show reported results: Y/N. Optional. (default: )
  --printed: string # Show printed results: Y/N. Optional. (default: )
  --limit: int # Limits the number of results. Optional. Valid values are 0-100. Default value: 10. (default: 10)
  --offset: int # Offset of the results returned. Optional. Default value: 0, which means that the first results will be returned. (default: 0)
]: nothing -> record<requested_resource: table<location: record, request: list, resource_metadata: record>, total_record_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "library" $library "scalar") (serialize-qp "circ_desk" $circ_desk "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "pickup_inst" $pickup_inst "scalar") (serialize-qp "reported" $reported "scalar") (serialize-qp "printed" $printed "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/requested-resources" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"library": $library, "circ_desk": $circ_desk, "location": $location, "order_by": $order_by, "direction": $direction, "pickup_inst": $pickup_inst, "reported": $reported, "printed": $printed, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Act on Requested Resources
#
# POST /almaws/v1/task-lists/requested-resources
# operationId: post/almaws/v1/task-lists/requested-resources
export def "almaws-task-lists-requested-resources create" [
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
  --library: string # The library of the given circulation desk or department where the resources are located. Mandatory. (default: )
  --circ-desk: string # The circulation desk where the action is being performed. Mandatory. (default: )
  --op: string # Operation to be preformed on the list of given requests. Currently the only supported action is 'mark_reported'. Mandatory. (default: )
  --location: string # The location code. Optional. (default: )
  --pickup-inst: string # The pickup institution. Optional. (default: )
  --reported: string # Show reported results: Y/N. Optional. (default: )
  --printed: string # Show printed results: Y/N. Optional. (default: )
]: nothing -> record<requested_resource: table<location: record, request: list, resource_metadata: record>, total_record_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "library" $library "scalar") (serialize-qp "circ_desk" $circ_desk "scalar") (serialize-qp "op" $op "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "pickup_inst" $pickup_inst "scalar") (serialize-qp "reported" $reported "scalar") (serialize-qp "printed" $printed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/requested-resources" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"library": $library, "circ_desk": $circ_desk, "op": $op, "location": $location, "pickup_inst": $pickup_inst, "reported": $reported, "printed": $printed} | compact), body: null}
}

# Get Lending Requests
#
# GET /almaws/v1/task-lists/rs/lending-requests
# operationId: get/almaws/v1/task-lists/rs/lending-requests
export def "almaws-task-lists-rs-lending-requests get" [
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
  --library: string # The resource sharing library for which lending requests should be retrieved. Mandatory. List of possible libraries can be retrieved using the [GET /almaws/v1/conf/libraries API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4Dp4I8TKv6CAxBlD4LyRaVE=/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --status: string # The status of lending requests to retrieve. Optional. List of possible statuses can be retrieved using the [GET almaws/v1/conf/code-tables/MandatoryLendingWorkflowSteps API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed) and the [GET almaws/v1/conf/code-tables/OptionalLendingWorkflowSteps API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --printed: string # The 'printed' value of lending requests to retrieve. Optional. Possible values: Y, N. (default: )
  --reported: string # The 'reported' value of lending requests to retrieve. Optional. Possible values: Y, N. (default: )
  --partner: string # The partner value. Only lending requests from this partner should be retrieved. Optional. List of possible partners can be retrieved using the [GET almaws/v1/partners API](https://developers.exlibrisgroup.com/alma/apis/partners/GET/gwPcGly021piAVNPLaef7suP1zfa6Lui/8883ef41-c3b8-4792-9ff8-cb6b729d6e07). (default: )
  --requested-format: string # Requested format of the resource. Optional. List of possible formats can be retrieved using the [GET almaws/v1/conf/code-tables/RequestFormats API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --supplied-format: string # Supplied Format of the resource. Optional. List of possible formats can be retrieved using the [GET almaws/v1/conf/code-tables/RequestFormats API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
]: nothing -> record<total_record_count: int, user_resource_sharing_request: table<additional_barcode: list, additional_person_name: string, agree_to_copyright_terms: bool, allow_other_formats: bool, author: string, author_initials: string, barcode: string, bib_note: string, call_number: string, chapter: string, chapter_author: string, chapter_title: string, citation_type: record, copyright_status: record, created_date: string, created_time: string, doi: string, edition: string, editor: string, end_page: string, external_id: string, format: record, fund: record, has_active_notes: bool, isbn: string, issn: string, issue: string, journal_title: string, last_interest_date: string, last_modified_date: string, last_modified_time: string, lcc_number: string, level_of_service: record, lost_damaged_fee: record, maximum_fee: float, mms_id: string, need_patron_info: bool, note: string, oclc_number: string, other_standard_id: string, owner: string, pages: string, part: string, partner: record, pickup_location: record, pickup_location_type: string, place_of_publication: string, pmid: string, preferred_send_method: record, printed: bool, publisher: string, reading_room: record, receive_cost: record, remote_record_id: string, reported: bool, request_cost: record, request_id: string, requested_language: record, requested_media: string, requester: record, rs_note: list, series_title_number: string, shipping_cost: record, source: string, specific_edition: bool, start_page: string, status: record, supplied_format: record, text_email: string, text_postal_1: string, text_postal_2: string, text_postal_3: string, text_postal_4: string, title: string, use_alternative_address: bool, user_request: record, volume: string, willing_to_pay: bool, year: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "library" $library "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "printed" $printed "scalar") (serialize-qp "reported" $reported "scalar") (serialize-qp "partner" $partner "scalar") (serialize-qp "requested_format" $requested_format "scalar") (serialize-qp "supplied_format" $supplied_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/rs/lending-requests" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"library": $library, "status": $status, "printed": $printed, "reported": $reported, "partner": $partner, "requested_format": $requested_format, "supplied_format": $supplied_format} | compact), body: null}
}

# Act on Lending Requests
#
# POST /almaws/v1/task-lists/rs/lending-requests
# operationId: post/almaws/v1/task-lists/rs/lending-requests
export def "almaws-task-lists-rs-lending-requests create" [
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
  --library: string # The resource sharing library from which lending requests should be retrieved. Mandatory. List of possible libraries can be retrieved using the [GET /almaws/v1/conf/libraries API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4Dp4I8TKv6CAxBlD4LyRaVE=/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --op: string # Operation to be preformed on the list of given requests. Currently the only supported action is 'mark_reported'. Mandatory. (default: )
  --status: string # The status of lending requests to retrieve. Optional. List of possible statuses can be retrieved using the [GET almaws/v1/conf/code-tables/MandatoryLendingWorkflowSteps API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed).and the [GET almaws/v1/conf/code-tables/OptionalLendingWorkflowSteps API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --printed: string # The 'printed' value of lending requests to retrieve. Optional. Possible values: Y, N. (default: )
  --reported: string # The 'reported' value of lending requests to retrieve. Optional. Possible values: Y, N. (default: )
  --partner: string # The partner value. Only lending requests from this partner should be. Optional. List of possible partners can be retrieved using the [GET almaws/v1/partners API](https://developers.exlibrisgroup.com/alma/apis/partners/GET/gwPcGly021piAVNPLaef7suP1zfa6Lui/8883ef41-c3b8-4792-9ff8-cb6b729d6e07). (default: )
  --requested-format: string # Requested format of the resource. Optional. List of possible formats can be retrieved using the [GET almaws/v1/conf/code-tables/RequestFormats API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --supplied-format: string # Supplied Format of the resource. Optional. List of possible formats can be retrieved using the [GET almaws/v1/conf/code-tables/RequestFormats API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
]: nothing -> record<additional_barcode: list<string>, additional_person_name: string, agree_to_copyright_terms: bool, allow_other_formats: bool, author: string, author_initials: string, barcode: string, bib_note: string, call_number: string, chapter: string, chapter_author: string, chapter_title: string, citation_type: record<desc: string, value: string>, copyright_status: record<desc: string, value: string>, created_date: string, created_time: string, doi: string, edition: string, editor: string, end_page: string, external_id: string, format: record<desc: string, value: string>, fund: record<desc: string, value: string>, has_active_notes: bool, isbn: string, issn: string, issue: string, journal_title: string, last_interest_date: string, last_modified_date: string, last_modified_time: string, lcc_number: string, level_of_service: record<desc: string, value: string>, lost_damaged_fee: record<currency: record<desc: string, value: string>, sum: float>, maximum_fee: float, mms_id: string, need_patron_info: bool, note: string, oclc_number: string, other_standard_id: string, owner: string, pages: string, part: string, partner: record<desc: string, value: string>, pickup_location: record<desc: string, value: string>, pickup_location_type: string, place_of_publication: string, pmid: string, preferred_send_method: record<desc: string, value: string>, printed: bool, publisher: string, reading_room: record<desc: string, value: string>, receive_cost: record<currency: record<desc: string, value: string>, sum: float>, remote_record_id: string, reported: bool, request_cost: record<currency: record<desc: string, value: string>, sum: float>, request_id: string, requested_language: record<desc: string, value: string>, requested_media: string, requester: record<desc: string, value: string>, rs_note: table<content: string, created_by: string, created_date: string>, series_title_number: string, shipping_cost: record<currency: record<desc: string, value: string>, sum: float>, source: string, specific_edition: bool, start_page: string, status: record<desc: string, value: string>, supplied_format: record<desc: string, value: string>, text_email: string, text_postal_1: string, text_postal_2: string, text_postal_3: string, text_postal_4: string, title: string, use_alternative_address: bool, user_request: record<link: string, value: string>, volume: string, willing_to_pay: bool, year: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "library" $library "scalar") (serialize-qp "op" $op "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "printed" $printed "scalar") (serialize-qp "reported" $reported "scalar") (serialize-qp "partner" $partner "scalar") (serialize-qp "requested_format" $requested_format "scalar") (serialize-qp "supplied_format" $supplied_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/rs/lending-requests" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"library": $library, "op": $op, "status": $status, "printed": $printed, "reported": $reported, "partner": $partner, "requested_format": $requested_format, "supplied_format": $supplied_format} | compact), body: null}
}

# GET Task-lists Test API
#
# GET /almaws/v1/task-lists/test
# operationId: get/almaws/v1/task-lists/test
export def "almaws-task-lists-test get" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/almaws/v1/task-lists/test")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST Task-lists Test API
#
# POST /almaws/v1/task-lists/test
# operationId: post/almaws/v1/task-lists/test
export def "almaws-task-lists-test create" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/almaws/v1/task-lists/test")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
