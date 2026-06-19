# Auto-generated client for Twilio - Supersim v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_supersim_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_SUPERSIM_TOKEN

const BASE_URL = "https://supersim.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_SUPERSIM_TOKEN | default "" }
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

def base-url-completer [] { ["https://supersim.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["available" "downloaded" "failed" "installed" "new" "reserving"] }
def callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def ip-commands-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def sms-commands-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-completer-1 [] { ["failed" "queued" "received" "sent"] }
def direction-completer [] { ["from_sim" "to_sim"] }
def payload-type-completer [] { ["binary" "text"] }
def status-completer-2 [] { ["failed" "in-progress" "scheduled" "successful"] }
def status-completer-3 [] { ["active" "inactive" "new" "ready" "scheduled"] }
def status-completer-4 [] { ["active" "inactive" "ready"] }
def status-completer-5 [] { ["delivered" "failed" "queued" "received" "sent"] }
def group-completer [] { ["fleet" "isoCountry" "network" "sim"] }
def granularity-completer [] { ["all" "day" "hour"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "e-sim-profiles list-esim" } } | get name | first)
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

# Retrieve a list of eSIM Profiles.
#
# GET /v1/ESimProfiles
# operationId: ListEsimProfile
export def "e-sim-profiles list-esim" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --eid: string # List the eSIM Profiles that have been associated with an EId.
  --sim-sid: string # Find the eSIM Profile resource related to a [Sim](https://www.twilio.com/docs/wireless/api/sim-resource) resource by providing the SIM SID. Will always return an array with either 1 or 0 records.
  --status: string@status-completer # List the eSIM Profiles that are in a given status.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<esim_profiles: table<account_sid: string, activation_code: string, date_created: string, date_updated: string, eid: string, error_code: string, error_message: string, iccid: string, matching_id: string, sid: string, sim_sid: string, smdp_plus_address: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let qp = [(serialize-qp "Eid" $eid "scalar") (serialize-qp "SimSid" $sim_sid "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ESimProfiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Eid": $eid, "SimSid": $sim_sid, "Status": $status, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Order an eSIM Profile.
#
# POST /v1/ESimProfiles
# operationId: CreateEsimProfile
export def "e-sim-profiles create-esim" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is POST. (format: http-method)
  --callback-url: string # The URL we should call using the `callback_method` when the status of the eSIM Profile changes. At this stage of the eSIM Profile pilot, the a request to the URL will only be called when the ESimProfile resource changes from `reserving` to `available`.
  --eid: string # Identifier of the eUICC that will claim the eSIM Profile.
  --generate-matching-id: oneof<nothing, bool> # When set to `true`, a value for `Eid` does not need to be provided. Instead, when the eSIM profile is reserved, a matching ID will be generated and returned via the `matching_id` property. This identifies the specific eSIM profile that can be used by any capable device to claim and download the profile.
]: any -> record<account_sid: string, activation_code: string, date_created: string, date_updated: string, eid: string, error_code: string, error_message: string, iccid: string, matching_id: string, sid: string, sim_sid: string, smdp_plus_address: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let full_url = (build-url $base "/v1/ESimProfiles")
  let req_body = {"CallbackMethod": $callback_method, "CallbackUrl": $callback_url, "Eid": $eid, "GenerateMatchingId": $generate_matching_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch an eSIM Profile.
#
# GET /v1/ESimProfiles/{Sid}
# operationId: FetchEsimProfile
export def "e-sim-profiles get-esim" [
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
]: nothing -> record<account_sid: string, activation_code: string, date_created: string, date_updated: string, eid: string, error_code: string, error_message: string, iccid: string, matching_id: string, sid: string, sim_sid: string, smdp_plus_address: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/ESimProfiles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of Fleets from your account.
#
# GET /v1/Fleets
# operationId: ListFleet
export def "fleets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --network-access-profile: string # The SID or unique name of the Network Access Profile that controls which cellular networks the Fleet's SIMs can connect to.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<fleets: table<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let qp = [(serialize-qp "NetworkAccessProfile" $network_access_profile "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Fleets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"NetworkAccessProfile": $network_access_profile, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a Fleet
#
# POST /v1/Fleets
# operationId: CreateFleet
export def "fleets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-enabled: oneof<nothing, bool> # Defines whether SIMs in the Fleet are capable of using 2G/3G/4G/LTE/CAT-M data connectivity. Defaults to `true`.
  --data-limit: int # The total data usage (download and upload combined) in Megabytes that each Super SIM assigned to the Fleet can consume during a billing period (normally one month). Value must be between 1MB (1) and 2TB (2,000,000). Defaults to 1GB (1,000).
  --ip-commands-method: string@ip-commands-method-completer # A string representing the HTTP method to use when making a request to `ip_commands_url`. Can be one of `POST` or `GET`. Defaults to `POST`. (format: http-method)
  --ip-commands-url: string # The URL that will receive a webhook when a Super SIM in the Fleet is used to send an IP Command from your device to a special IP address. Your server should respond with an HTTP status code in the 200 range; any response body will be ignored. (format: uri)
  network_access_profile: string # The SID or unique name of the Network Access Profile that will control which cellular networks the Fleet's SIMs can connect to.
  --sms-commands-enabled: oneof<nothing, bool> # Defines whether SIMs in the Fleet are capable of sending and receiving machine-to-machine SMS via Commands. Defaults to `true`.
  --sms-commands-method: string@sms-commands-method-completer # A string representing the HTTP method to use when making a request to `sms_commands_url`. Can be one of `POST` or `GET`. Defaults to `POST`. (format: http-method)
  --sms-commands-url: string # The URL that will receive a webhook when a Super SIM in the Fleet is used to send an SMS from your device to the SMS Commands number. Your server should respond with an HTTP status code in the 200 range; any response body will be ignored. (format: uri)
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
]: any -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let full_url = (build-url $base "/v1/Fleets")
  let req_body = {"DataEnabled": $data_enabled, "DataLimit": $data_limit, "IpCommandsMethod": $ip_commands_method, "IpCommandsUrl": $ip_commands_url, "NetworkAccessProfile": $network_access_profile, "SmsCommandsEnabled": $sms_commands_enabled, "SmsCommandsMethod": $sms_commands_method, "SmsCommandsUrl": $sms_commands_url, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch a Fleet instance from your account.
#
# GET /v1/Fleets/{Sid}
# operationId: FetchFleet
export def "fleets get" [
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
]: nothing -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Fleets/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the given properties of a Super SIM Fleet instance from your account.
#
# POST /v1/Fleets/{Sid}
# operationId: UpdateFleet
export def "fleets update" [
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
  --data-limit: int # The total data usage (download and upload combined) in Megabytes that each Super SIM assigned to the Fleet can consume during a billing period (normally one month). Value must be between 1MB (1) and 2TB (2,000,000). Defaults to 1GB (1,000).
  --ip-commands-method: string@ip-commands-method-completer # A string representing the HTTP method to use when making a request to `ip_commands_url`. Can be one of `POST` or `GET`. Defaults to `POST`. (format: http-method)
  --ip-commands-url: string # The URL that will receive a webhook when a Super SIM in the Fleet is used to send an IP Command from your device to a special IP address. Your server should respond with an HTTP status code in the 200 range; any response body will be ignored. (format: uri)
  --network-access-profile: string # The SID or unique name of the Network Access Profile that will control which cellular networks the Fleet's SIMs can connect to.
  --sms-commands-method: string@sms-commands-method-completer # A string representing the HTTP method to use when making a request to `sms_commands_url`. Can be one of `POST` or `GET`. Defaults to `POST`. (format: http-method)
  --sms-commands-url: string # The URL that will receive a webhook when a Super SIM in the Fleet is used to send an SMS from your device to the SMS Commands number. Your server should respond with an HTTP status code in the 200 range; any response body will be ignored. (format: uri)
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
]: any -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Fleets/{sid}"))
  let req_body = {"DataLimit": $data_limit, "IpCommandsMethod": $ip_commands_method, "IpCommandsUrl": $ip_commands_url, "NetworkAccessProfile": $network_access_profile, "SmsCommandsMethod": $sms_commands_method, "SmsCommandsUrl": $sms_commands_url, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of IP Commands from your account.
#
# GET /v1/IpCommands
# operationId: ListIpCommand
export def "ip-commands list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim: string # The SID or unique name of the Sim resource that IP Command was sent to or from.
  --sim-iccid: string # The ICCID of the Sim resource that IP Command was sent to or from.
  --status: string@status-completer-1 # The status of the IP Command. Can be: `queued`, `sent`, `received` or `failed`. See the [IP Command Status Values](https://www.twilio.com/docs/wireless/api/ipcommand-resource#status-values) for a description of each.
  --direction: string@direction-completer # The direction of the IP Command. Can be `to_sim` or `from_sim`. The value of `to_sim` is synonymous with the term `mobile terminated`, and `from_sim` is synonymous with the term `mobile originated`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<ip_commands: table<account_sid: string, date_created: string, date_updated: string, device_ip: string, device_port: int, direction: string, payload: string, payload_type: string, sid: string, sim_iccid: string, sim_sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let qp = [(serialize-qp "Sim" $sim "scalar") (serialize-qp "SimIccid" $sim_iccid "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "Direction" $direction "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/IpCommands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Sim": $sim, "SimIccid": $sim_iccid, "Status": $status, "Direction": $direction, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Send an IP Command to a Super SIM.
#
# POST /v1/IpCommands
# operationId: CreateIpCommand
export def "ip-commands create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be `GET` or `POST`, and the default is `POST`. (format: http-method)
  --callback-url: string # The URL we should call using the `callback_method` after we have sent the IP Command. (format: uri)
  device_port: int # The device port to which the IP Command will be sent.
  payload: string # The data that will be sent to the device. The payload cannot exceed 1300 bytes. If the PayloadType is set to text, the payload is encoded in UTF-8. If PayloadType is set to binary, the payload is encoded in Base64.
  --payload-type: string@payload-type-completer
  sim: string # The `sid` or `unique_name` of the [Super SIM](https://www.twilio.com/docs/iot/supersim/api/sim-resource) to send the IP Command to.
]: any -> record<account_sid: string, date_created: string, date_updated: string, device_ip: string, device_port: int, direction: string, payload: string, payload_type: string, sid: string, sim_iccid: string, sim_sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let full_url = (build-url $base "/v1/IpCommands")
  let req_body = {"CallbackMethod": $callback_method, "CallbackUrl": $callback_url, "DevicePort": $device_port, "Payload": $payload, "PayloadType": $payload_type, "Sim": $sim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch IP Command instance from your account.
#
# GET /v1/IpCommands/{Sid}
# operationId: FetchIpCommand
export def "ip-commands get" [
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, device_ip: string, device_port: int, direction: string, payload: string, payload_type: string, sid: string, sim_iccid: string, sim_sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/IpCommands/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of Network Access Profiles from your account.
#
# GET /v1/NetworkAccessProfiles
# operationId: ListNetworkAccessProfile
export def "network-access-profiles list" [
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, network_access_profiles: table<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/NetworkAccessProfiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Network Access Profile
#
# POST /v1/NetworkAccessProfiles
# operationId: CreateNetworkAccessProfile
export def "network-access-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --networks: list<string> # List of Network SIDs that this Network Access Profile will allow connections to.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
]: any -> record<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let full_url = (build-url $base "/v1/NetworkAccessProfiles")
  let req_body = {"Networks": $networks, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of Network Access Profile resource's Network resource.
#
# GET /v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks
# operationId: ListNetworkAccessProfileNetwork
export def "network-access-profiles-networks list" [
  network_access_profile_sid: string
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, networks: table<friendly_name: string, identifiers: list, iso_country: string, network_access_profile_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($network_access_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'NetworkAccessProfileSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_access_profile_sid: (encode-path-segment $network_access_profile_sid)} | format pattern "/v1/NetworkAccessProfiles/{network_access_profile_sid}/Networks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Add a Network resource to the Network Access Profile resource.
#
# POST /v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks
# operationId: CreateNetworkAccessProfileNetwork
export def "network-access-profiles-networks create" [
  network_access_profile_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  network: string # The SID of the Network resource to be added to the Network Access Profile resource.
]: any -> record<friendly_name: string, identifiers: list<any>, iso_country: string, network_access_profile_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($network_access_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'NetworkAccessProfileSid' must be non-empty" } }
  let full_url = (build-url $base ({network_access_profile_sid: (encode-path-segment $network_access_profile_sid)} | format pattern "/v1/NetworkAccessProfiles/{network_access_profile_sid}/Networks"))
  let req_body = {"Network": $network} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Remove a Network resource from the Network Access Profile resource's.
#
# DELETE /v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks/{Sid}
# operationId: DeleteNetworkAccessProfileNetwork
export def "network-access-profiles-networks delete" [
  network_access_profile_sid: string
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
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($network_access_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'NetworkAccessProfileSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({network_access_profile_sid: (encode-path-segment $network_access_profile_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/NetworkAccessProfiles/{network_access_profile_sid}/Networks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a Network Access Profile resource's Network resource.
#
# GET /v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks/{Sid}
# operationId: FetchNetworkAccessProfileNetwork
export def "network-access-profiles-networks get" [
  network_access_profile_sid: string
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
]: nothing -> record<friendly_name: string, identifiers: list<any>, iso_country: string, network_access_profile_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($network_access_profile_sid | is-empty) { error make --unspanned { msg: "path parameter 'NetworkAccessProfileSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({network_access_profile_sid: (encode-path-segment $network_access_profile_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/NetworkAccessProfiles/{network_access_profile_sid}/Networks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a Network Access Profile instance from your account.
#
# GET /v1/NetworkAccessProfiles/{Sid}
# operationId: FetchNetworkAccessProfile
export def "network-access-profiles get" [
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/NetworkAccessProfiles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the given properties of a Network Access Profile in your account.
#
# POST /v1/NetworkAccessProfiles/{Sid}
# operationId: UpdateNetworkAccessProfile
export def "network-access-profiles update" [
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
  --unique-name: string # The new unique name of the Network Access Profile.
]: any -> record<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/NetworkAccessProfiles/{sid}"))
  let req_body = {"UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of Network resources.
#
# GET /v1/Networks
# operationId: ListNetwork
export def "networks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iso-country: string # The [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) of the Network resources to read.
  --mcc: string # The 'mobile country code' of a country. Network resources with this `mcc` in their `identifiers` will be read.
  --mnc: string # The 'mobile network code' of a mobile operator network. Network resources with this `mnc` in their `identifiers` will be read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, networks: table<friendly_name: string, identifiers: list, iso_country: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let qp = [(serialize-qp "IsoCountry" $iso_country "scalar") (serialize-qp "Mcc" $mcc "scalar") (serialize-qp "Mnc" $mnc "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"IsoCountry": $iso_country, "Mcc": $mcc, "Mnc": $mnc, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Fetch a Network resource.
#
# GET /v1/Networks/{Sid}
# operationId: FetchNetwork
export def "networks get" [
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
]: nothing -> record<friendly_name: string, identifiers: list<any>, iso_country: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Networks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of Settings Updates.
#
# GET /v1/SettingsUpdates
# operationId: ListSettingsUpdate
export def "settings-updates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim: string # Filter the Settings Updates by a Super SIM's SID or UniqueName.
  --status: string@status-completer-2 # Filter the Settings Updates by status. Can be `scheduled`, `in-progress`, `successful`, or `failed`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, settings_updates: table<date_completed: string, date_created: string, date_updated: string, iccid: string, packages: list, sid: string, sim_sid: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let qp = [(serialize-qp "Sim" $sim "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/SettingsUpdates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Sim": $sim, "Status": $status, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Retrieve a list of Super SIMs from your account.
#
# GET /v1/Sims
# operationId: ListSim
export def "sims list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # The status of the Sim resources to read. Can be `new`, `ready`, `active`, `inactive`, or `scheduled`.
  --fleet: string # The SID or unique name of the Fleet to which a list of Sims are assigned.
  --iccid: string # The [ICCID](https://en.wikipedia.org/wiki/Subscriber_identity_module#ICCID) associated with a Super SIM to filter the list by. Passing this parameter will always return a list containing zero or one SIMs.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sims: table<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "Fleet" $fleet "scalar") (serialize-qp "Iccid" $iccid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Sims" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Status": $status, "Fleet": $fleet, "Iccid": $iccid, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Register a Super SIM to your Account
#
# POST /v1/Sims
# operationId: CreateSim
export def "sims create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  iccid: string # The [ICCID](https://en.wikipedia.org/wiki/Subscriber_identity_module#ICCID) of the Super SIM to be added to your Account.
  registration_code: string # The 10-digit code required to claim the Super SIM for your Account.
]: any -> record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let full_url = (build-url $base "/v1/Sims")
  let req_body = {"Iccid": $iccid, "RegistrationCode": $registration_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch a Super SIM instance from your account.
#
# GET /v1/Sims/{Sid}
# operationId: FetchSim
export def "sims get" [
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Sims/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the given properties of a Super SIM instance from your account.
#
# POST /v1/Sims/{Sid}
# operationId: UpdateSim
export def "sims update" [
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
  --account-sid: string # The SID of the Account to which the Sim resource should belong. The Account SID can only be that of the requesting Account or that of a Subaccount of the requesting Account. Only valid when the Sim resource's status is new.
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is POST. (format: http-method)
  --callback-url: string # The URL we should call using the `callback_method` after an asynchronous update has finished. (format: uri)
  --fleet: string # The SID or unique name of the Fleet to which the SIM resource should be assigned.
  --status: string@status-completer-4
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
]: any -> record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Sims/{sid}"))
  let req_body = {"AccountSid": $account_sid, "CallbackMethod": $callback_method, "CallbackUrl": $callback_url, "Fleet": $fleet, "Status": $status, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of Billing Periods for a Super SIM.
#
# GET /v1/Sims/{SimSid}/BillingPeriods
# operationId: ListBillingPeriod
export def "sims-billing-periods list" [
  sim_sid: string
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
]: nothing -> record<billing_periods: table<account_sid: string, date_created: string, date_updated: string, end_time: string, period_type: string, sid: string, sim_sid: string, start_time: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sim_sid | is-empty) { error make --unspanned { msg: "path parameter 'SimSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sim_sid: (encode-path-segment $sim_sid)} | format pattern "/v1/Sims/{sim_sid}/BillingPeriods") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Retrieve a list of IP Addresses for the given Super SIM.
#
# GET /v1/Sims/{SimSid}/IpAddresses
# operationId: ListSimIpAddress
export def "sims-ip-addresses list-address" [
  sim_sid: string
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
]: nothing -> record<ip_addresses: table<ip_address: string, ip_address_version: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sim_sid | is-empty) { error make --unspanned { msg: "path parameter 'SimSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sim_sid: (encode-path-segment $sim_sid)} | format pattern "/v1/Sims/{sim_sid}/IpAddresses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Retrieve a list of SMS Commands from your account.
#
# GET /v1/SmsCommands
# operationId: ListSmsCommand
export def "sms-commands list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim: string # The SID or unique name of the Sim resource that SMS Command was sent to or from.
  --status: string@status-completer-5 # The status of the SMS Command. Can be: `queued`, `sent`, `delivered`, `received` or `failed`. See the [SMS Command Status Values](https://www.twilio.com/docs/iot/supersim/api/smscommand-resource#status-values) for a description of each.
  --direction: string@direction-completer # The direction of the SMS Command. Can be `to_sim` or `from_sim`. The value of `to_sim` is synonymous with the term `mobile terminated`, and `from_sim` is synonymous with the term `mobile originated`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sms_commands: table<account_sid: string, date_created: string, date_updated: string, direction: string, payload: string, sid: string, sim_sid: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let qp = [(serialize-qp "Sim" $sim "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "Direction" $direction "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/SmsCommands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Sim": $sim, "Status": $status, "Direction": $direction, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Send SMS Command to a Sim.
#
# POST /v1/SmsCommands
# operationId: CreateSmsCommand
export def "sms-commands create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is POST. (format: http-method)
  --callback-url: string # The URL we should call using the `callback_method` after we have sent the command. (format: uri)
  payload: string # The message body of the SMS Command.
  sim: string # The `sid` or `unique_name` of the [SIM](https://www.twilio.com/docs/iot/supersim/api/sim-resource) to send the SMS Command to.
]: any -> record<account_sid: string, date_created: string, date_updated: string, direction: string, payload: string, sid: string, sim_sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let full_url = (build-url $base "/v1/SmsCommands")
  let req_body = {"CallbackMethod": $callback_method, "CallbackUrl": $callback_url, "Payload": $payload, "Sim": $sim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch SMS Command instance from your account.
#
# GET /v1/SmsCommands/{Sid}
# operationId: FetchSmsCommand
export def "sms-commands get" [
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, direction: string, payload: string, sid: string, sim_sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/SmsCommands/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List UsageRecords
#
# GET /v1/UsageRecords
# operationId: ListUsageRecord
export def "usage-records list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim: string # SID or unique name of a Sim resource. Only show UsageRecords representing usage incurred by this Super SIM.
  --fleet: string # SID or unique name of a Fleet resource. Only show UsageRecords representing usage for Super SIMs belonging to this Fleet resource at the time the usage occurred.
  --network: string # SID of a Network resource. Only show UsageRecords representing usage on this network.
  --iso-country: string # Alpha-2 ISO Country Code. Only show UsageRecords representing usage in this country. (format: iso-country-code)
  --group: string@group-completer # Dimension over which to aggregate usage records. Can be: `sim`, `fleet`, `network`, `isoCountry`. Default is to not aggregate across any of these dimensions, UsageRecords will be aggregated into the time buckets described by the `Granularity` parameter.
  --granularity: string@granularity-completer # Time-based grouping that UsageRecords should be aggregated by. Can be: `hour`, `day`, or `all`. Default is `all`. `all` returns one UsageRecord that describes the usage for the entire period.
  --start-time: string # Only include usage that occurred at or after this time, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. Default is one month before the `end_time`. (format: date-time)
  --end-time: string # Only include usage that occurred before this time (exclusive), specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. Default is the current time. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, usage_records: table<account_sid: string, billed_unit: string, data_download: int, data_total: int, data_total_billed: float, data_upload: int, fleet_sid: string, iso_country: string, network_sid: string, period: any, sim_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://supersim.twilio.com")
  let qp = [(serialize-qp "Sim" $sim "scalar") (serialize-qp "Fleet" $fleet "scalar") (serialize-qp "Network" $network "scalar") (serialize-qp "IsoCountry" $iso_country "scalar") (serialize-qp "Group" $group "scalar") (serialize-qp "Granularity" $granularity "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/UsageRecords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Sim": $sim, "Fleet": $fleet, "Network": $network, "IsoCountry": $iso_country, "Group": $group, "Granularity": $granularity, "StartTime": $start_time, "EndTime": $end_time, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}
