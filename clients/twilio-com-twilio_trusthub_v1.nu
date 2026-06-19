# Auto-generated client for Twilio - Trusthub v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_trusthub_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_TRUSTHUB_TOKEN

const BASE_URL = "https://trusthub.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_TRUSTHUB_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://trusthub.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["draft" "in-review" "pending-review" "twilio-approved" "twilio-rejected"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "customer-profiles list" } } | get name | first)
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

# Retrieve a list of all Customer-Profiles for an account.
#
# GET /v1/CustomerProfiles
# operationId: ListCustomerProfile
export def "customer-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The verification status of the Customer-Profile resource.
  --friendly-name: string # The string that you assigned to describe the resource.
  --policy-sid: string # The unique string of a policy that is associated to the Customer-Profile resource.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PolicySid" $policy_sid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/CustomerProfiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Status": $status, "FriendlyName": $friendly_name, "PolicySid": $policy_sid, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Customer-Profile.
#
# POST /v1/CustomerProfiles
# operationId: CreateCustomerProfile
export def "customer-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address that will receive updates when the Customer-Profile resource changes status.
  friendly_name: string # The string that you assigned to describe the resource.
  policy_sid: string # The unique string of a policy that is associated to the Customer-Profile resource.
  --status-callback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base "/v1/CustomerProfiles")
  let req_body = {"Email": $email, "FriendlyName": $friendly_name, "PolicySid": $policy_sid, "StatusCallback": $status_callback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/ChannelEndpointAssignments
# operationId: ListCustomerProfileChannelEndpointAssignment
export def "customer-profiles-channel-endpoint-assignments list" [
  customer_profile_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-endpoint-sid: string # The SID of an channel endpoint
  --channel-endpoint-sids: string # comma separated list of channel endpoint sids
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, customer_profile_sid: string, date_created: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  let qp = [(serialize-qp "ChannelEndpointSid" $channel_endpoint_sid "scalar") (serialize-qp "ChannelEndpointSids" $channel_endpoint_sids "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/ChannelEndpointAssignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ChannelEndpointSid": $channel_endpoint_sid, "ChannelEndpointSids": $channel_endpoint_sids, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Assigned Item.
#
# POST /v1/CustomerProfiles/{CustomerProfileSid}/ChannelEndpointAssignments
# operationId: CreateCustomerProfileChannelEndpointAssignment
export def "customer-profiles-channel-endpoint-assignments create" [
  customer_profile_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_endpoint_sid: string # The SID of an channel endpoint
  channel_endpoint_type: string # The type of channel endpoint. eg: phone-number
]: any -> record<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, customer_profile_sid: string, date_created: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/ChannelEndpointAssignments"))
  let req_body = {"ChannelEndpointSid": $channel_endpoint_sid, "ChannelEndpointType": $channel_endpoint_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Remove an Assignment Item Instance.
#
# DELETE /v1/CustomerProfiles/{CustomerProfileSid}/ChannelEndpointAssignments/{Sid}
# operationId: DeleteCustomerProfileChannelEndpointAssignment
export def "customer-profiles-channel-endpoint-assignments delete" [
  customer_profile_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/ChannelEndpointAssignments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch specific Assigned Item Instance.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/ChannelEndpointAssignments/{Sid}
# operationId: FetchCustomerProfileChannelEndpointAssignment
export def "customer-profiles-channel-endpoint-assignments get" [
  customer_profile_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, customer_profile_sid: string, date_created: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/ChannelEndpointAssignments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/EntityAssignments
# operationId: ListCustomerProfileEntityAssignment
export def "customer-profiles-entity-assignments list" [
  customer_profile_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, customer_profile_sid: string, date_created: string, object_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/EntityAssignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Assigned Item.
#
# POST /v1/CustomerProfiles/{CustomerProfileSid}/EntityAssignments
# operationId: CreateCustomerProfileEntityAssignment
export def "customer-profiles-entity-assignments create" [
  customer_profile_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  object_sid: string # The SID of an object bag that holds information of the different items.
]: any -> record<account_sid: string, customer_profile_sid: string, date_created: string, object_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/EntityAssignments"))
  let req_body = {"ObjectSid": $object_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Remove an Assignment Item Instance.
#
# DELETE /v1/CustomerProfiles/{CustomerProfileSid}/EntityAssignments/{Sid}
# operationId: DeleteCustomerProfileEntityAssignment
export def "customer-profiles-entity-assignments delete" [
  customer_profile_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/EntityAssignments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch specific Assigned Item Instance.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/EntityAssignments/{Sid}
# operationId: FetchCustomerProfileEntityAssignment
export def "customer-profiles-entity-assignments get" [
  customer_profile_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, customer_profile_sid: string, date_created: string, object_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/EntityAssignments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of Evaluations associated to the customer_profile resource.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/Evaluations
# operationId: ListCustomerProfileEvaluation
export def "customer-profiles-evaluations list" [
  customer_profile_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, customer_profile_sid: string, date_created: string, policy_sid: string, results: list, sid: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/Evaluations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Evaluation
#
# POST /v1/CustomerProfiles/{CustomerProfileSid}/Evaluations
# operationId: CreateCustomerProfileEvaluation
export def "customer-profiles-evaluations create" [
  customer_profile_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  policy_sid: string # The unique string of a policy that is associated to the customer_profile resource.
]: any -> record<account_sid: string, customer_profile_sid: string, date_created: string, policy_sid: string, results: list<any>, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/Evaluations"))
  let req_body = {"PolicySid": $policy_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch specific Evaluation Instance.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/Evaluations/{Sid}
# operationId: FetchCustomerProfileEvaluation
export def "customer-profiles-evaluations get" [
  customer_profile_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, customer_profile_sid: string, date_created: string, policy_sid: string, results: list<any>, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($customer_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'CustomerProfileSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({customer_profile_sid: (encode-path-segment $customer_profile_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/CustomerProfiles/{customer_profile_sid}/Evaluations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a specific Customer-Profile.
#
# DELETE /v1/CustomerProfiles/{Sid}
# operationId: DeleteCustomerProfile
export def "customer-profiles delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/CustomerProfiles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a specific Customer-Profile instance.
#
# GET /v1/CustomerProfiles/{Sid}
# operationId: FetchCustomerProfile
export def "customer-profiles get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/CustomerProfiles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a Customer-Profile in an account.
#
# POST /v1/CustomerProfiles/{Sid}
# operationId: UpdateCustomerProfile
export def "customer-profiles update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address that will receive updates when the Customer-Profile resource changes status.
  --friendly-name: string # The string that you assigned to describe the resource.
  --status: string@status-completer
  --status-callback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/CustomerProfiles/{sid}"))
  let req_body = {"Email": $email, "FriendlyName": $friendly_name, "Status": $status, "StatusCallback": $status_callback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all End-User Types.
#
# GET /v1/EndUserTypes
# operationId: ListEndUserType
export def "end-user-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end_user_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/EndUserTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Fetch a specific End-User Type Instance.
#
# GET /v1/EndUserTypes/{Sid}
# operationId: FetchEndUserType
export def "end-user-types get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/EndUserTypes/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of all End User for an account.
#
# GET /v1/EndUsers
# operationId: ListEndUser
export def "end-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/EndUsers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new End User.
#
# POST /v1/EndUsers
# operationId: CreateEndUser
export def "end-users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: any # The set of parameters that are the attributes of the End User resource which are derived End User Types.
  friendly_name: string # The string that you assigned to describe the resource.
  type: string # The type of end user of the Bundle resource - can be `individual` or `business`.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base "/v1/EndUsers")
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a specific End User.
#
# DELETE /v1/EndUsers/{Sid}
# operationId: DeleteEndUser
export def "end-users delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/EndUsers/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch specific End User Instance.
#
# GET /v1/EndUsers/{Sid}
# operationId: FetchEndUser
export def "end-users get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/EndUsers/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an existing End User.
#
# POST /v1/EndUsers/{Sid}
# operationId: UpdateEndUser
export def "end-users update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: any # The set of parameters that are the attributes of the End User resource which are derived End User Types.
  --friendly-name: string # The string that you assigned to describe the resource.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/EndUsers/{sid}"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Policys.
#
# GET /v1/Policies
# operationId: ListPolicies
export def "policies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<friendly_name: string, requirements: any, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Fetch specific Policy Instance.
#
# GET /v1/Policies/{Sid}
# operationId: FetchPolicies
export def "policies get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<friendly_name: string, requirements: any, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Policies/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of all Supporting Document Types.
#
# GET /v1/SupportingDocumentTypes
# operationId: ListSupportingDocumentType
export def "supporting-document-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, supporting_document_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/SupportingDocumentTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Fetch a specific Supporting Document Type Instance.
#
# GET /v1/SupportingDocumentTypes/{Sid}
# operationId: FetchSupportingDocumentType
export def "supporting-document-types get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/SupportingDocumentTypes/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of all Supporting Document for an account.
#
# GET /v1/SupportingDocuments
# operationId: ListSupportingDocument
export def "supporting-documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/SupportingDocuments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Supporting Document.
#
# POST /v1/SupportingDocuments
# operationId: CreateSupportingDocument
export def "supporting-documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: any # The set of parameters that are the attributes of the Supporting Documents resource which are derived Supporting Document Types.
  friendly_name: string # The string that you assigned to describe the resource.
  type: string # The type of the Supporting Document.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base "/v1/SupportingDocuments")
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a specific Supporting Document.
#
# DELETE /v1/SupportingDocuments/{Sid}
# operationId: DeleteSupportingDocument
export def "supporting-documents delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/SupportingDocuments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch specific Supporting Document Instance.
#
# GET /v1/SupportingDocuments/{Sid}
# operationId: FetchSupportingDocument
export def "supporting-documents get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/SupportingDocuments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an existing Supporting Document.
#
# POST /v1/SupportingDocuments/{Sid}
# operationId: UpdateSupportingDocument
export def "supporting-documents update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: any # The set of parameters that are the attributes of the Supporting Document resource which are derived Supporting Document Types.
  --friendly-name: string # The string that you assigned to describe the resource.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/SupportingDocuments/{sid}"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Customer-Profiles for an account.
#
# GET /v1/TrustProducts
# operationId: ListTrustProduct
export def "trust-products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The verification status of the Customer-Profile resource.
  --friendly-name: string # The string that you assigned to describe the resource.
  --policy-sid: string # The unique string of a policy that is associated to the Customer-Profile resource.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PolicySid" $policy_sid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/TrustProducts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Status": $status, "FriendlyName": $friendly_name, "PolicySid": $policy_sid, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Customer-Profile.
#
# POST /v1/TrustProducts
# operationId: CreateTrustProduct
export def "trust-products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address that will receive updates when the Customer-Profile resource changes status.
  friendly_name: string # The string that you assigned to describe the resource.
  policy_sid: string # The unique string of a policy that is associated to the Customer-Profile resource.
  --status-callback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base "/v1/TrustProducts")
  let req_body = {"Email": $email, "FriendlyName": $friendly_name, "PolicySid": $policy_sid, "StatusCallback": $status_callback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a specific Customer-Profile.
#
# DELETE /v1/TrustProducts/{Sid}
# operationId: DeleteTrustProduct
export def "trust-products delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/TrustProducts/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a specific Customer-Profile instance.
#
# GET /v1/TrustProducts/{Sid}
# operationId: FetchTrustProduct
export def "trust-products get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/TrustProducts/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a Customer-Profile in an account.
#
# POST /v1/TrustProducts/{Sid}
# operationId: UpdateTrustProduct
export def "trust-products update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address that will receive updates when the Customer-Profile resource changes status.
  --friendly-name: string # The string that you assigned to describe the resource.
  --status: string@status-completer
  --status-callback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/TrustProducts/{sid}"))
  let req_body = {"Email": $email, "FriendlyName": $friendly_name, "Status": $status, "StatusCallback": $status_callback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v1/TrustProducts/{TrustProductSid}/ChannelEndpointAssignments
# operationId: ListTrustProductChannelEndpointAssignment
export def "trust-products-channel-endpoint-assignments list" [
  trust_product_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-endpoint-sid: string # The SID of an channel endpoint
  --channel-endpoint-sids: string # comma separated list of channel endpoint sids
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, date_created: string, sid: string, trust_product_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  let qp = [(serialize-qp "ChannelEndpointSid" $channel_endpoint_sid "scalar") (serialize-qp "ChannelEndpointSids" $channel_endpoint_sids "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/ChannelEndpointAssignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ChannelEndpointSid": $channel_endpoint_sid, "ChannelEndpointSids": $channel_endpoint_sids, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Assigned Item.
#
# POST /v1/TrustProducts/{TrustProductSid}/ChannelEndpointAssignments
# operationId: CreateTrustProductChannelEndpointAssignment
export def "trust-products-channel-endpoint-assignments create" [
  trust_product_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_endpoint_sid: string # The SID of an channel endpoint
  channel_endpoint_type: string # The type of channel endpoint. eg: phone-number
]: any -> record<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, date_created: string, sid: string, trust_product_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/ChannelEndpointAssignments"))
  let req_body = {"ChannelEndpointSid": $channel_endpoint_sid, "ChannelEndpointType": $channel_endpoint_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Remove an Assignment Item Instance.
#
# DELETE /v1/TrustProducts/{TrustProductSid}/ChannelEndpointAssignments/{Sid}
# operationId: DeleteTrustProductChannelEndpointAssignment
export def "trust-products-channel-endpoint-assignments delete" [
  trust_product_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/ChannelEndpointAssignments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch specific Assigned Item Instance.
#
# GET /v1/TrustProducts/{TrustProductSid}/ChannelEndpointAssignments/{Sid}
# operationId: FetchTrustProductChannelEndpointAssignment
export def "trust-products-channel-endpoint-assignments get" [
  trust_product_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, date_created: string, sid: string, trust_product_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/ChannelEndpointAssignments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v1/TrustProducts/{TrustProductSid}/EntityAssignments
# operationId: ListTrustProductEntityAssignment
export def "trust-products-entity-assignments list" [
  trust_product_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, object_sid: string, sid: string, trust_product_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/EntityAssignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Assigned Item.
#
# POST /v1/TrustProducts/{TrustProductSid}/EntityAssignments
# operationId: CreateTrustProductEntityAssignment
export def "trust-products-entity-assignments create" [
  trust_product_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  object_sid: string # The SID of an object bag that holds information of the different items.
]: any -> record<account_sid: string, date_created: string, object_sid: string, sid: string, trust_product_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/EntityAssignments"))
  let req_body = {"ObjectSid": $object_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Remove an Assignment Item Instance.
#
# DELETE /v1/TrustProducts/{TrustProductSid}/EntityAssignments/{Sid}
# operationId: DeleteTrustProductEntityAssignment
export def "trust-products-entity-assignments delete" [
  trust_product_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/EntityAssignments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch specific Assigned Item Instance.
#
# GET /v1/TrustProducts/{TrustProductSid}/EntityAssignments/{Sid}
# operationId: FetchTrustProductEntityAssignment
export def "trust-products-entity-assignments get" [
  trust_product_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, object_sid: string, sid: string, trust_product_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/EntityAssignments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of Evaluations associated to the trust_product resource.
#
# GET /v1/TrustProducts/{TrustProductSid}/Evaluations
# operationId: ListTrustProductEvaluation
export def "trust-products-evaluations list" [
  trust_product_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, policy_sid: string, results: list, sid: string, status: string, trust_product_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/Evaluations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Evaluation
#
# POST /v1/TrustProducts/{TrustProductSid}/Evaluations
# operationId: CreateTrustProductEvaluation
export def "trust-products-evaluations create" [
  trust_product_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  policy_sid: string # The unique string of a policy that is associated to the customer_profile resource.
]: any -> record<account_sid: string, date_created: string, policy_sid: string, results: list<any>, sid: string, status: string, trust_product_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/Evaluations"))
  let req_body = {"PolicySid": $policy_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch specific Evaluation Instance.
#
# GET /v1/TrustProducts/{TrustProductSid}/Evaluations/{Sid}
# operationId: FetchTrustProductEvaluation
export def "trust-products-evaluations get" [
  trust_product_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, policy_sid: string, results: list<any>, sid: string, status: string, trust_product_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  if ($trust_product_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrustProductSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trust_product_sid: (encode-path-segment $trust_product_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/TrustProducts/{trust_product_sid}/Evaluations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
