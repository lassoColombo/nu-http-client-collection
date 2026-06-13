# Auto-generated client for Ex Libris APIs v1.0
# Source: https://api.apis.guru/v2/specs/exlibrisgroup.com/tasklists/1.0/openapi.json
# Auth: --token flag or $env.EX_LIBRIS_APIS_TOKEN

const BASE_URL = "https://api-eu.hosted.exlibrisgroup.com"
const DEFAULT_AUTH = "query-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EX_LIBRIS_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-apikey" => { {headers: {}, query: $"apikey=($token_val)"} }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["https://api-eu.hosted.exlibrisgroup.com" "https://api-na.hosted.exlibrisgroup.com" "https://api-ap.hosted.exlibrisgroup.com" "https://api-cn.hosted.exlibrisgroup.com" "https://api-ca.hosted.exlibrisgroup.com"] }
def auth-scheme-completer [] { ["query-apikey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "almaws-task-lists-printouts get/almaws/v1/task-lists/printouts" } } | get name | first)
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
export def "almaws-task-lists-printouts get/almaws/v1/task-lists/printouts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --letter: string # Printout Name. Optional.  (default: ALL)
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Act on Printouts
#
# POST /almaws/v1/task-lists/printouts
# operationId: post/almaws/v1/task-lists/printouts
export def "almaws-task-lists-printouts post/almaws/v1/task-lists/printouts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --letter: string # Printout Name. Optional.  (default: ALL)
  --status: string # Printout status. Optional. Valid values are: Printed, Pending, Canceled. (default: ALL)
  --printer-id: string # Printout Printer (default: ALL)
  --printout-id: string # A list of Printout IDs (for example: 123,456,778) from 1 to the limit of 100 Optional. Use of this option overrides all of the filtering parameters (default: ALL)
  --op: string # The operation to perform on the printout. Currently, the options are: 'mark_as_printed','mark_as_canceled'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "letter" $letter "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "printer_id" $printer_id "scalar") (serialize-qp "printout_id" $printout_id "scalar") (serialize-qp "op" $op "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/printouts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Printout
#
# GET /almaws/v1/task-lists/printouts/{printout_id}
# operationId: get/almaws/v1/task-lists/printouts/{printout_id}
export def "almaws-task-lists-printouts id}-by-printout_id" [
  printout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/almaws/v1/task-lists/printouts/($printout_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Printout Service
#
# POST /almaws/v1/task-lists/printouts/{printout_id}
# operationId: post/almaws/v1/task-lists/printouts/{printout_id}
export def "almaws-task-lists-printouts id}-by-printout_id-1" [
  printout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --op: string # The operation to perform on the printout. Currently, the options are 'mark_as_printed','mark_as_canceled'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "op" $op "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/almaws/v1/task-lists/printouts/($printout_id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Requested Resources
#
# GET /almaws/v1/task-lists/requested-resources
# operationId: get/almaws/v1/task-lists/requested-resources
export def "almaws-task-lists-requested-resources get/almaws/v1/task-lists/requested-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Act on Requested Resources
#
# POST /almaws/v1/task-lists/requested-resources
# operationId: post/almaws/v1/task-lists/requested-resources
export def "almaws-task-lists-requested-resources post/almaws/v1/task-lists/requested-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --library: string # The library of the given circulation desk or department where the resources are located. Mandatory. (default: )
  --circ-desk: string # The circulation desk where the action is being performed. Mandatory. (default: )
  --op: string # Operation to be preformed on the list of given requests. Currently the only supported action is 'mark_reported'. Mandatory. (default: )
  --location: string # The location code. Optional. (default: )
  --pickup-inst: string # The pickup institution. Optional. (default: )
  --reported: string # Show reported results: Y/N. Optional. (default: )
  --printed: string # Show printed results: Y/N. Optional. (default: )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "library" $library "scalar") (serialize-qp "circ_desk" $circ_desk "scalar") (serialize-qp "op" $op "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "pickup_inst" $pickup_inst "scalar") (serialize-qp "reported" $reported "scalar") (serialize-qp "printed" $printed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/requested-resources" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Lending Requests
#
# GET /almaws/v1/task-lists/rs/lending-requests
# operationId: get/almaws/v1/task-lists/rs/lending-requests
export def "almaws-task-lists-rs-lending-requests get/almaws/v1/task-lists/rs/lending-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --library: string # The resource sharing library for which lending requests should be retrieved. Mandatory. List of possible libraries can be retrieved using the [GET /almaws/v1/conf/libraries API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4Dp4I8TKv6CAxBlD4LyRaVE=/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --status: string # The status of lending requests to retrieve. Optional. List of possible statuses can be retrieved using the [GET almaws/v1/conf/code-tables/MandatoryLendingWorkflowSteps API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed) and the  [GET almaws/v1/conf/code-tables/OptionalLendingWorkflowSteps API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --printed: string # The 'printed' value of lending requests to retrieve. Optional. Possible values: Y, N. (default: )
  --reported: string # The 'reported' value of lending requests to retrieve. Optional. Possible values: Y, N. (default: )
  --partner: string # The partner value. Only lending requests from this partner should be retrieved. Optional. List of possible partners can be retrieved using the [GET almaws/v1/partners API](https://developers.exlibrisgroup.com/alma/apis/partners/GET/gwPcGly021piAVNPLaef7suP1zfa6Lui/8883ef41-c3b8-4792-9ff8-cb6b729d6e07). (default: )
  --requested-format: string # Requested format of the resource. Optional. List of possible formats can be retrieved using the [GET almaws/v1/conf/code-tables/RequestFormats API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --supplied-format: string # Supplied Format of the resource. Optional. List of possible formats can be retrieved using the [GET almaws/v1/conf/code-tables/RequestFormats API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
]: nothing -> record<total_record_count: int, user_resource_sharing_request: table<additional_barcode: list, additional_person_name: string, agree_to_copyright_terms: bool, allow_other_formats: bool, author: string, author_initials: string, barcode: string, bib_note: string, call_number: string, chapter: string, chapter_author: string, chapter_title: string, citation_type: record, copyright_status: record, created_date: string, created_time: string, doi: string, edition: string, editor: string, end_page: string, external_id: string, format: record, fund: record, has_active_notes: bool, isbn: string, issn: string, issue: string, journal_title: string, last_interest_date: string, last_modified_date: string, last_modified_time: string, lcc_number: string, level_of_service: record, lost_damaged_fee: any, maximum_fee: float, mms_id: string, need_patron_info: bool, note: string, oclc_number: string, other_standard_id: string, owner: string, pages: string, part: string, partner: record, pickup_location: record, pickup_location_type: string, place_of_publication: string, pmid: string, preferred_send_method: record, printed: bool, publisher: string, reading_room: record, receive_cost: any, remote_record_id: string, reported: bool, request_cost: any, request_id: string, requested_language: record, requested_media: string, requester: record, rs_note: list, series_title_number: string, shipping_cost: record, source: string, specific_edition: bool, start_page: string, status: record, supplied_format: record, text_email: string, text_postal_1: string, text_postal_2: string, text_postal_3: string, text_postal_4: string, title: string, use_alternative_address: bool, user_request: record, volume: string, willing_to_pay: bool, year: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "library" $library "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "printed" $printed "scalar") (serialize-qp "reported" $reported "scalar") (serialize-qp "partner" $partner "scalar") (serialize-qp "requested_format" $requested_format "scalar") (serialize-qp "supplied_format" $supplied_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/rs/lending-requests" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Act on Lending Requests
#
# POST /almaws/v1/task-lists/rs/lending-requests
# operationId: post/almaws/v1/task-lists/rs/lending-requests
export def "almaws-task-lists-rs-lending-requests post/almaws/v1/task-lists/rs/lending-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --library: string # The resource sharing library from which lending requests should be retrieved. Mandatory. List of possible libraries can be retrieved using the [GET /almaws/v1/conf/libraries API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4Dp4I8TKv6CAxBlD4LyRaVE=/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --op: string # Operation to be preformed on the list of given requests. Currently the only supported action is 'mark_reported'. Mandatory. (default: )
  --status: string # The status of lending requests to retrieve. Optional. List of possible statuses can be retrieved using the [GET almaws/v1/conf/code-tables/MandatoryLendingWorkflowSteps API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed).and the  [GET almaws/v1/conf/code-tables/OptionalLendingWorkflowSteps API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --printed: string # The 'printed' value of lending requests to retrieve. Optional. Possible values: Y, N. (default: )
  --reported: string # The 'reported' value of lending requests to retrieve. Optional. Possible values: Y, N. (default: )
  --partner: string # The partner value. Only lending requests from this partner should be. Optional. List of possible partners can be retrieved using the [GET almaws/v1/partners API](https://developers.exlibrisgroup.com/alma/apis/partners/GET/gwPcGly021piAVNPLaef7suP1zfa6Lui/8883ef41-c3b8-4792-9ff8-cb6b729d6e07). (default: )
  --requested-format: string # Requested format of the resource. Optional. List of possible formats can be retrieved using the [GET almaws/v1/conf/code-tables/RequestFormats API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
  --supplied-format: string # Supplied Format of the resource. Optional. List of possible formats can be retrieved using the [GET almaws/v1/conf/code-tables/RequestFormats API](https://developers.exlibrisgroup.com/alma/apis/conf/GET/gwPcGly021p29HpB7XTI4K7cQ0vuYHLS4NSgDGmcRpRYqx5hIMRTng9SIKO5Vof+/37088dc9-c685-4641-bc7f-60b5ca7cabed). (default: )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "library" $library "scalar") (serialize-qp "op" $op "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "printed" $printed "scalar") (serialize-qp "reported" $reported "scalar") (serialize-qp "partner" $partner "scalar") (serialize-qp "requested_format" $requested_format "scalar") (serialize-qp "supplied_format" $supplied_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/almaws/v1/task-lists/rs/lending-requests" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET Task-lists Test API
#
# GET /almaws/v1/task-lists/test
# operationId: get/almaws/v1/task-lists/test
export def "almaws-task-lists-test get/almaws/v1/task-lists/test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/almaws/v1/task-lists/test")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST Task-lists Test API
#
# POST /almaws/v1/task-lists/test
# operationId: post/almaws/v1/task-lists/test
export def "almaws-task-lists-test post/almaws/v1/task-lists/test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/almaws/v1/task-lists/test")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
