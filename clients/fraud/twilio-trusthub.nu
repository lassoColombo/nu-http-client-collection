# Auto-generated client for Twilio - Trusthub v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_trusthub_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_TRUSTHUB_TOKEN

const BASE_URL = "https://trusthub.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_TRUSTHUB_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://trusthub.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def Status-completer [] { ["draft" "in-review" "pending-review" "twilio-approved" "twilio-rejected"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "customer-profiles ListCustomerProfile" } } | get name | first)
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
export def "customer-profiles ListCustomerProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Status: string@Status-completer # The verification status of the Customer-Profile resource.
  --FriendlyName: string # The string that you assigned to describe the resource.
  --PolicySid: string # The unique string of a policy that is associated to the Customer-Profile resource.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "Status" $Status "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PolicySid" $PolicySid "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/CustomerProfiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Customer-Profile.
#
# POST /v1/CustomerProfiles
# operationId: CreateCustomerProfile
export def "customer-profiles CreateCustomerProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Email: string # The email address that will receive updates when the Customer-Profile resource changes status.
  FriendlyName: string # The string that you assigned to describe the resource.
  PolicySid: string # The unique string of a policy that is associated to the Customer-Profile resource.
  --StatusCallback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base "/v1/CustomerProfiles")
  let body = {Email: $Email, FriendlyName: $FriendlyName, PolicySid: $PolicySid, StatusCallback: $StatusCallback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/ChannelEndpointAssignments
# operationId: ListCustomerProfileChannelEndpointAssignment
export def "customer-profiles-channel-endpoint-assignments ListCustomerProfileChannelEndpointAssignment" [
  CustomerProfileSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ChannelEndpointSid: string # The SID of an channel endpoint
  --ChannelEndpointSids: string # comma separated list of channel endpoint sids
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, customer_profile_sid: string, date_created: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "ChannelEndpointSid" $ChannelEndpointSid "scalar") (serialize-qp "ChannelEndpointSids" $ChannelEndpointSids "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/ChannelEndpointAssignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Assigned Item.
#
# POST /v1/CustomerProfiles/{CustomerProfileSid}/ChannelEndpointAssignments
# operationId: CreateCustomerProfileChannelEndpointAssignment
export def "customer-profiles-channel-endpoint-assignments CreateCustomerProfileChannelEndpointAssignment" [
  CustomerProfileSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ChannelEndpointSid: string # The SID of an channel endpoint
  ChannelEndpointType: string # The type of channel endpoint. eg: phone-number
]: any -> record<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, customer_profile_sid: string, date_created: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/ChannelEndpointAssignments")
  let body = {ChannelEndpointSid: $ChannelEndpointSid, ChannelEndpointType: $ChannelEndpointType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an Assignment Item Instance.
#
# DELETE /v1/CustomerProfiles/{CustomerProfileSid}/ChannelEndpointAssignments/{Sid}
# operationId: DeleteCustomerProfileChannelEndpointAssignment
export def "customer-profiles-channel-endpoint-assignments DeleteCustomerProfileChannelEndpointAssignment" [
  CustomerProfileSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/ChannelEndpointAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch specific Assigned Item Instance.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/ChannelEndpointAssignments/{Sid}
# operationId: FetchCustomerProfileChannelEndpointAssignment
export def "customer-profiles-channel-endpoint-assignments FetchCustomerProfileChannelEndpointAssignment" [
  CustomerProfileSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, customer_profile_sid: string, date_created: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/ChannelEndpointAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/EntityAssignments
# operationId: ListCustomerProfileEntityAssignment
export def "customer-profiles-entity-assignments ListCustomerProfileEntityAssignment" [
  CustomerProfileSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, customer_profile_sid: string, date_created: string, object_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/EntityAssignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Assigned Item.
#
# POST /v1/CustomerProfiles/{CustomerProfileSid}/EntityAssignments
# operationId: CreateCustomerProfileEntityAssignment
export def "customer-profiles-entity-assignments CreateCustomerProfileEntityAssignment" [
  CustomerProfileSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ObjectSid: string # The SID of an object bag that holds information of the different items.
]: any -> record<account_sid: string, customer_profile_sid: string, date_created: string, object_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/EntityAssignments")
  let body = {ObjectSid: $ObjectSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an Assignment Item Instance.
#
# DELETE /v1/CustomerProfiles/{CustomerProfileSid}/EntityAssignments/{Sid}
# operationId: DeleteCustomerProfileEntityAssignment
export def "customer-profiles-entity-assignments DeleteCustomerProfileEntityAssignment" [
  CustomerProfileSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/EntityAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch specific Assigned Item Instance.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/EntityAssignments/{Sid}
# operationId: FetchCustomerProfileEntityAssignment
export def "customer-profiles-entity-assignments FetchCustomerProfileEntityAssignment" [
  CustomerProfileSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, customer_profile_sid: string, date_created: string, object_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/EntityAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of Evaluations associated to the customer_profile resource.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/Evaluations
# operationId: ListCustomerProfileEvaluation
export def "customer-profiles-evaluations ListCustomerProfileEvaluation" [
  CustomerProfileSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, customer_profile_sid: string, date_created: string, policy_sid: string, results: list, sid: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/Evaluations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Evaluation
#
# POST /v1/CustomerProfiles/{CustomerProfileSid}/Evaluations
# operationId: CreateCustomerProfileEvaluation
export def "customer-profiles-evaluations CreateCustomerProfileEvaluation" [
  CustomerProfileSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  PolicySid: string # The unique string of a policy that is associated to the customer_profile resource.
]: any -> record<account_sid: string, customer_profile_sid: string, date_created: string, policy_sid: string, results: list<any>, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/Evaluations")
  let body = {PolicySid: $PolicySid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch specific Evaluation Instance.
#
# GET /v1/CustomerProfiles/{CustomerProfileSid}/Evaluations/{Sid}
# operationId: FetchCustomerProfileEvaluation
export def "customer-profiles-evaluations FetchCustomerProfileEvaluation" [
  CustomerProfileSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, customer_profile_sid: string, date_created: string, policy_sid: string, results: list<any>, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($CustomerProfileSid)/Evaluations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a specific Customer-Profile.
#
# DELETE /v1/CustomerProfiles/{Sid}
# operationId: DeleteCustomerProfile
export def "customer-profiles DeleteCustomerProfile" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific Customer-Profile instance.
#
# GET /v1/CustomerProfiles/{Sid}
# operationId: FetchCustomerProfile
export def "customer-profiles FetchCustomerProfile" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a Customer-Profile in an account.
#
# POST /v1/CustomerProfiles/{Sid}
# operationId: UpdateCustomerProfile
export def "customer-profiles UpdateCustomerProfile" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Email: string # The email address that will receive updates when the Customer-Profile resource changes status.
  --FriendlyName: string # The string that you assigned to describe the resource.
  --Status: string@Status-completer
  --StatusCallback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/CustomerProfiles/($Sid)")
  let body = {Email: $Email, FriendlyName: $FriendlyName, Status: $Status, StatusCallback: $StatusCallback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all End-User Types.
#
# GET /v1/EndUserTypes
# operationId: ListEndUserType
export def "end-user-types ListEndUserType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end_user_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/EndUserTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific End-User Type Instance.
#
# GET /v1/EndUserTypes/{Sid}
# operationId: FetchEndUserType
export def "end-user-types FetchEndUserType" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/EndUserTypes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all End User for an account.
#
# GET /v1/EndUsers
# operationId: ListEndUser
export def "end-users ListEndUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/EndUsers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new End User.
#
# POST /v1/EndUsers
# operationId: CreateEndUser
export def "end-users CreateEndUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Attributes: any # The set of parameters that are the attributes of the End User resource which are derived End User Types.
  FriendlyName: string # The string that you assigned to describe the resource.
  Type: string # The type of end user of the Bundle resource - can be `individual` or `business`.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base "/v1/EndUsers")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific End User.
#
# DELETE /v1/EndUsers/{Sid}
# operationId: DeleteEndUser
export def "end-users DeleteEndUser" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/EndUsers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch specific End User Instance.
#
# GET /v1/EndUsers/{Sid}
# operationId: FetchEndUser
export def "end-users FetchEndUser" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/EndUsers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing End User.
#
# POST /v1/EndUsers/{Sid}
# operationId: UpdateEndUser
export def "end-users UpdateEndUser" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Attributes: any # The set of parameters that are the attributes of the End User resource which are derived End User Types.
  --FriendlyName: string # The string that you assigned to describe the resource.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/EndUsers/($Sid)")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Policys.
#
# GET /v1/Policies
# operationId: ListPolicies
export def "policies ListPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<friendly_name: string, requirements: any, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch specific Policy Instance.
#
# GET /v1/Policies/{Sid}
# operationId: FetchPolicies
export def "policies FetchPolicies" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<friendly_name: string, requirements: any, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/Policies/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all Supporting Document Types.
#
# GET /v1/SupportingDocumentTypes
# operationId: ListSupportingDocumentType
export def "supporting-document-types ListSupportingDocumentType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, supporting_document_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/SupportingDocumentTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific Supporting Document Type Instance.
#
# GET /v1/SupportingDocumentTypes/{Sid}
# operationId: FetchSupportingDocumentType
export def "supporting-document-types FetchSupportingDocumentType" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/SupportingDocumentTypes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all Supporting Document for an account.
#
# GET /v1/SupportingDocuments
# operationId: ListSupportingDocument
export def "supporting-documents ListSupportingDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/SupportingDocuments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Supporting Document.
#
# POST /v1/SupportingDocuments
# operationId: CreateSupportingDocument
export def "supporting-documents CreateSupportingDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Attributes: any # The set of parameters that are the attributes of the Supporting Documents resource which are derived Supporting Document Types.
  FriendlyName: string # The string that you assigned to describe the resource.
  Type: string # The type of the Supporting Document.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base "/v1/SupportingDocuments")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Supporting Document.
#
# DELETE /v1/SupportingDocuments/{Sid}
# operationId: DeleteSupportingDocument
export def "supporting-documents DeleteSupportingDocument" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/SupportingDocuments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch specific Supporting Document Instance.
#
# GET /v1/SupportingDocuments/{Sid}
# operationId: FetchSupportingDocument
export def "supporting-documents FetchSupportingDocument" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/SupportingDocuments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing Supporting Document.
#
# POST /v1/SupportingDocuments/{Sid}
# operationId: UpdateSupportingDocument
export def "supporting-documents UpdateSupportingDocument" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Attributes: any # The set of parameters that are the attributes of the Supporting Document resource which are derived Supporting Document Types.
  --FriendlyName: string # The string that you assigned to describe the resource.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/SupportingDocuments/($Sid)")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Customer-Profiles for an account.
#
# GET /v1/TrustProducts
# operationId: ListTrustProduct
export def "trust-products ListTrustProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Status: string@Status-completer # The verification status of the Customer-Profile resource.
  --FriendlyName: string # The string that you assigned to describe the resource.
  --PolicySid: string # The unique string of a policy that is associated to the Customer-Profile resource.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "Status" $Status "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PolicySid" $PolicySid "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/TrustProducts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Customer-Profile.
#
# POST /v1/TrustProducts
# operationId: CreateTrustProduct
export def "trust-products CreateTrustProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Email: string # The email address that will receive updates when the Customer-Profile resource changes status.
  FriendlyName: string # The string that you assigned to describe the resource.
  PolicySid: string # The unique string of a policy that is associated to the Customer-Profile resource.
  --StatusCallback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base "/v1/TrustProducts")
  let body = {Email: $Email, FriendlyName: $FriendlyName, PolicySid: $PolicySid, StatusCallback: $StatusCallback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Customer-Profile.
#
# DELETE /v1/TrustProducts/{Sid}
# operationId: DeleteTrustProduct
export def "trust-products DeleteTrustProduct" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific Customer-Profile instance.
#
# GET /v1/TrustProducts/{Sid}
# operationId: FetchTrustProduct
export def "trust-products FetchTrustProduct" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a Customer-Profile in an account.
#
# POST /v1/TrustProducts/{Sid}
# operationId: UpdateTrustProduct
export def "trust-products UpdateTrustProduct" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Email: string # The email address that will receive updates when the Customer-Profile resource changes status.
  --FriendlyName: string # The string that you assigned to describe the resource.
  --Status: string@Status-completer
  --StatusCallback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, policy_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($Sid)")
  let body = {Email: $Email, FriendlyName: $FriendlyName, Status: $Status, StatusCallback: $StatusCallback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v1/TrustProducts/{TrustProductSid}/ChannelEndpointAssignments
# operationId: ListTrustProductChannelEndpointAssignment
export def "trust-products-channel-endpoint-assignments ListTrustProductChannelEndpointAssignment" [
  TrustProductSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ChannelEndpointSid: string # The SID of an channel endpoint
  --ChannelEndpointSids: string # comma separated list of channel endpoint sids
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, date_created: string, sid: string, trust_product_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "ChannelEndpointSid" $ChannelEndpointSid "scalar") (serialize-qp "ChannelEndpointSids" $ChannelEndpointSids "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/ChannelEndpointAssignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Assigned Item.
#
# POST /v1/TrustProducts/{TrustProductSid}/ChannelEndpointAssignments
# operationId: CreateTrustProductChannelEndpointAssignment
export def "trust-products-channel-endpoint-assignments CreateTrustProductChannelEndpointAssignment" [
  TrustProductSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ChannelEndpointSid: string # The SID of an channel endpoint
  ChannelEndpointType: string # The type of channel endpoint. eg: phone-number
]: any -> record<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, date_created: string, sid: string, trust_product_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/ChannelEndpointAssignments")
  let body = {ChannelEndpointSid: $ChannelEndpointSid, ChannelEndpointType: $ChannelEndpointType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an Assignment Item Instance.
#
# DELETE /v1/TrustProducts/{TrustProductSid}/ChannelEndpointAssignments/{Sid}
# operationId: DeleteTrustProductChannelEndpointAssignment
export def "trust-products-channel-endpoint-assignments DeleteTrustProductChannelEndpointAssignment" [
  TrustProductSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/ChannelEndpointAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch specific Assigned Item Instance.
#
# GET /v1/TrustProducts/{TrustProductSid}/ChannelEndpointAssignments/{Sid}
# operationId: FetchTrustProductChannelEndpointAssignment
export def "trust-products-channel-endpoint-assignments FetchTrustProductChannelEndpointAssignment" [
  TrustProductSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, channel_endpoint_sid: string, channel_endpoint_type: string, date_created: string, sid: string, trust_product_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/ChannelEndpointAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v1/TrustProducts/{TrustProductSid}/EntityAssignments
# operationId: ListTrustProductEntityAssignment
export def "trust-products-entity-assignments ListTrustProductEntityAssignment" [
  TrustProductSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, object_sid: string, sid: string, trust_product_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/EntityAssignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Assigned Item.
#
# POST /v1/TrustProducts/{TrustProductSid}/EntityAssignments
# operationId: CreateTrustProductEntityAssignment
export def "trust-products-entity-assignments CreateTrustProductEntityAssignment" [
  TrustProductSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ObjectSid: string # The SID of an object bag that holds information of the different items.
]: any -> record<account_sid: string, date_created: string, object_sid: string, sid: string, trust_product_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/EntityAssignments")
  let body = {ObjectSid: $ObjectSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an Assignment Item Instance.
#
# DELETE /v1/TrustProducts/{TrustProductSid}/EntityAssignments/{Sid}
# operationId: DeleteTrustProductEntityAssignment
export def "trust-products-entity-assignments DeleteTrustProductEntityAssignment" [
  TrustProductSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/EntityAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch specific Assigned Item Instance.
#
# GET /v1/TrustProducts/{TrustProductSid}/EntityAssignments/{Sid}
# operationId: FetchTrustProductEntityAssignment
export def "trust-products-entity-assignments FetchTrustProductEntityAssignment" [
  TrustProductSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, object_sid: string, sid: string, trust_product_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/EntityAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of Evaluations associated to the trust_product resource.
#
# GET /v1/TrustProducts/{TrustProductSid}/Evaluations
# operationId: ListTrustProductEvaluation
export def "trust-products-evaluations ListTrustProductEvaluation" [
  TrustProductSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, policy_sid: string, results: list, sid: string, status: string, trust_product_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/Evaluations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Evaluation
#
# POST /v1/TrustProducts/{TrustProductSid}/Evaluations
# operationId: CreateTrustProductEvaluation
export def "trust-products-evaluations CreateTrustProductEvaluation" [
  TrustProductSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  PolicySid: string # The unique string of a policy that is associated to the customer_profile resource.
]: any -> record<account_sid: string, date_created: string, policy_sid: string, results: list<any>, sid: string, status: string, trust_product_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/Evaluations")
  let body = {PolicySid: $PolicySid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch specific Evaluation Instance.
#
# GET /v1/TrustProducts/{TrustProductSid}/Evaluations/{Sid}
# operationId: FetchTrustProductEvaluation
export def "trust-products-evaluations FetchTrustProductEvaluation" [
  TrustProductSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, date_created: string, policy_sid: string, results: list<any>, sid: string, status: string, trust_product_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trusthub.twilio.com")
  let full_url = (build-url $base $"/v1/TrustProducts/($TrustProductSid)/Evaluations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
