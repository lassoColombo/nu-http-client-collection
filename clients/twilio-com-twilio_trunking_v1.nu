# Auto-generated client for Twilio - Trunking v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_trunking_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_TRUNKING_TOKEN

const BASE_URL = "https://trunking.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TWILIO_TRUNKING_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://trunking.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def disaster-recovery-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def transfer-caller-id-completer [] { ["from-transferee" "from-transferor"] }
def transfer-mode-completer [] { ["disable-all" "enable-all" "sip-only"] }
def mode-completer [] { ["do-not-record" "record-from-answer" "record-from-answer-dual" "record-from-ringing" "record-from-ringing-dual"] }
def trim-completer [] { ["do-not-trim" "trim-silence"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "trunks list" } } | get name | first)
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

# GET /v1/Trunks
#
# operationId: ListTrunk
export def "trunks list" [
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, trunks: table<account_sid: string, auth_type: string, auth_type_set: list, cnam_lookup_enabled: bool, date_created: string, date_updated: string, disaster_recovery_method: string, disaster_recovery_url: string, domain_name: string, friendly_name: string, links: record, recording: any, secure: bool, sid: string, transfer_caller_id: string, transfer_mode: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Trunks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Trunks
#
# operationId: CreateTrunk
export def "trunks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cnam-lookup-enabled: oneof<nothing, bool> # Whether Caller ID Name (CNAM) lookup should be enabled for the trunk. If enabled, all inbound calls to the SIP Trunk from the United States and Canada automatically perform a CNAM Lookup and display Caller ID data on your phone. See [CNAM Lookups](https://www.twilio.com/docs/sip-trunking#CNAM) for more information.
  --disaster-recovery-method: string@disaster-recovery-method-completer # The HTTP method we should use to call the `disaster_recovery_url`. Can be: `GET` or `POST`. (format: http-method)
  --disaster-recovery-url: string # The URL we should call using the `disaster_recovery_method` if an error occurs while sending SIP traffic towards the configured Origination URL. We retrieve TwiML from the URL and execute the instructions like any other normal TwiML call. See [Disaster Recovery](https://www.twilio.com/docs/sip-trunking#disaster-recovery) for more information. (format: uri)
  --domain-name: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and `-` and must end with `pstn.twilio.com`. See [Termination Settings](https://www.twilio.com/docs/sip-trunking#termination) for more information.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --secure: oneof<nothing, bool> # Whether Secure Trunking is enabled for the trunk. If enabled, all calls going through the trunk will be secure using SRTP for media and TLS for signaling. If disabled, then RTP will be used for media. See [Secure Trunking](https://www.twilio.com/docs/sip-trunking#securetrunking) for more information.
  --transfer-caller-id: string@transfer-caller-id-completer
  --transfer-mode: string@transfer-mode-completer
]: any -> record<account_sid: string, auth_type: string, auth_type_set: list<string>, cnam_lookup_enabled: bool, date_created: string, date_updated: string, disaster_recovery_method: string, disaster_recovery_url: string, domain_name: string, friendly_name: string, links: record, recording: any, secure: bool, sid: string, transfer_caller_id: string, transfer_mode: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base "/v1/Trunks" $auth.query)
  let req_body = {"CnamLookupEnabled": $cnam_lookup_enabled, "DisasterRecoveryMethod": $disaster_recovery_method, "DisasterRecoveryUrl": $disaster_recovery_url, "DomainName": $domain_name, "FriendlyName": $friendly_name, "Secure": $secure, "TransferCallerId": $transfer_caller_id, "TransferMode": $transfer_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Trunks/{Sid}
#
# operationId: DeleteTrunk
export def "trunks delete" [
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
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /v1/Trunks/{Sid}
#
# operationId: FetchTrunk
export def "trunks get" [
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
]: nothing -> record<account_sid: string, auth_type: string, auth_type_set: list<string>, cnam_lookup_enabled: bool, date_created: string, date_updated: string, disaster_recovery_method: string, disaster_recovery_url: string, domain_name: string, friendly_name: string, links: record, recording: any, secure: bool, sid: string, transfer_caller_id: string, transfer_mode: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Trunks/{Sid}
#
# operationId: UpdateTrunk
export def "trunks update" [
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
  --cnam-lookup-enabled: oneof<nothing, bool> # Whether Caller ID Name (CNAM) lookup should be enabled for the trunk. If enabled, all inbound calls to the SIP Trunk from the United States and Canada automatically perform a CNAM Lookup and display Caller ID data on your phone. See [CNAM Lookups](https://www.twilio.com/docs/sip-trunking#CNAM) for more information.
  --disaster-recovery-method: string@disaster-recovery-method-completer # The HTTP method we should use to call the `disaster_recovery_url`. Can be: `GET` or `POST`. (format: http-method)
  --disaster-recovery-url: string # The URL we should call using the `disaster_recovery_method` if an error occurs while sending SIP traffic towards the configured Origination URL. We retrieve TwiML from the URL and execute the instructions like any other normal TwiML call. See [Disaster Recovery](https://www.twilio.com/docs/sip-trunking#disaster-recovery) for more information. (format: uri)
  --domain-name: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and `-` and must end with `pstn.twilio.com`. See [Termination Settings](https://www.twilio.com/docs/sip-trunking#termination) for more information.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --secure: oneof<nothing, bool> # Whether Secure Trunking is enabled for the trunk. If enabled, all calls going through the trunk will be secure using SRTP for media and TLS for signaling. If disabled, then RTP will be used for media. See [Secure Trunking](https://www.twilio.com/docs/sip-trunking#securetrunking) for more information.
  --transfer-caller-id: string@transfer-caller-id-completer
  --transfer-mode: string@transfer-mode-completer
]: any -> record<account_sid: string, auth_type: string, auth_type_set: list<string>, cnam_lookup_enabled: bool, date_created: string, date_updated: string, disaster_recovery_method: string, disaster_recovery_url: string, domain_name: string, friendly_name: string, links: record, recording: any, secure: bool, sid: string, transfer_caller_id: string, transfer_mode: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{sid}") $auth.query)
  let req_body = {"CnamLookupEnabled": $cnam_lookup_enabled, "DisasterRecoveryMethod": $disaster_recovery_method, "DisasterRecoveryUrl": $disaster_recovery_url, "DomainName": $domain_name, "FriendlyName": $friendly_name, "Secure": $secure, "TransferCallerId": $transfer_caller_id, "TransferMode": $transfer_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# GET /v1/Trunks/{TrunkSid}/CredentialLists
#
# operationId: ListCredentialList
export def "trunks-credential-lists list" [
  trunk_sid: string
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
]: nothing -> record<credential_lists: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, trunk_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/CredentialLists") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Trunks/{TrunkSid}/CredentialLists
#
# operationId: CreateCredentialList
export def "trunks-credential-lists create" [
  trunk_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  credential_list_sid: string # The SID of the [Credential List](https://www.twilio.com/docs/voice/sip/api/sip-credentiallist-resource) that you want to associate with the trunk. Once associated, we will authenticate access to the trunk against this list.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, trunk_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/CredentialLists") $auth.query)
  let req_body = {"CredentialListSid": $credential_list_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Trunks/{TrunkSid}/CredentialLists/{Sid}
#
# operationId: DeleteCredentialList
export def "trunks-credential-lists delete" [
  trunk_sid: string
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
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{trunk_sid}/CredentialLists/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /v1/Trunks/{TrunkSid}/CredentialLists/{Sid}
#
# operationId: FetchCredentialList
export def "trunks-credential-lists get" [
  trunk_sid: string
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, trunk_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{trunk_sid}/CredentialLists/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all IP Access Control Lists for a Trunk
#
# GET /v1/Trunks/{TrunkSid}/IpAccessControlLists
# operationId: ListIpAccessControlList
export def "trunks-ip-access-control-lists list" [
  trunk_sid: string
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
]: nothing -> record<ip_access_control_lists: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, trunk_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/IpAccessControlLists") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Associate an IP Access Control List with a Trunk
#
# POST /v1/Trunks/{TrunkSid}/IpAccessControlLists
# operationId: CreateIpAccessControlList
export def "trunks-ip-access-control-lists create" [
  trunk_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ip_access_control_list_sid: string # The SID of the [IP Access Control List](https://www.twilio.com/docs/voice/sip/api/sip-ipaccesscontrollist-resource) that you want to associate with the trunk.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, trunk_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/IpAccessControlLists") $auth.query)
  let req_body = {"IpAccessControlListSid": $ip_access_control_list_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Remove an associated IP Access Control List from a Trunk
#
# DELETE /v1/Trunks/{TrunkSid}/IpAccessControlLists/{Sid}
# operationId: DeleteIpAccessControlList
export def "trunks-ip-access-control-lists delete" [
  trunk_sid: string
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
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{trunk_sid}/IpAccessControlLists/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /v1/Trunks/{TrunkSid}/IpAccessControlLists/{Sid}
#
# operationId: FetchIpAccessControlList
export def "trunks-ip-access-control-lists get" [
  trunk_sid: string
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, trunk_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{trunk_sid}/IpAccessControlLists/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /v1/Trunks/{TrunkSid}/OriginationUrls
#
# operationId: ListOriginationUrl
export def "trunks-origination-urls list" [
  trunk_sid: string
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, origination_urls: table<account_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, sip_url: string, trunk_sid: string, url: string, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/OriginationUrls") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Trunks/{TrunkSid}/OriginationUrls
#
# operationId: CreateOriginationUrl
export def "trunks-origination-urls create" [
  trunk_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether the URL is enabled. The default is `true`.
  friendly_name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  priority: int # The relative importance of the URI. Can be an integer from 0 to 65535, inclusive, and the default is 10. The lowest number represents the most important URI.
  sip_url: string # The SIP address you want Twilio to route your Origination calls to. This must be a `sip:` schema. (format: uri)
  weight: int # The value that determines the relative share of the load the URI should receive compared to other URIs with the same priority. Can be an integer from 1 to 65535, inclusive, and the default is 10. URLs with higher values receive more load than those with lower ones with the same priority.
]: any -> record<account_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, sip_url: string, trunk_sid: string, url: string, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/OriginationUrls") $auth.query)
  let req_body = {"Enabled": $enabled, "FriendlyName": $friendly_name, "Priority": $priority, "SipUrl": $sip_url, "Weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Trunks/{TrunkSid}/OriginationUrls/{Sid}
#
# operationId: DeleteOriginationUrl
export def "trunks-origination-urls delete" [
  trunk_sid: string
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
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{trunk_sid}/OriginationUrls/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /v1/Trunks/{TrunkSid}/OriginationUrls/{Sid}
#
# operationId: FetchOriginationUrl
export def "trunks-origination-urls get" [
  trunk_sid: string
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, sip_url: string, trunk_sid: string, url: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{trunk_sid}/OriginationUrls/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Trunks/{TrunkSid}/OriginationUrls/{Sid}
#
# operationId: UpdateOriginationUrl
export def "trunks-origination-urls update" [
  trunk_sid: string
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
  --enabled: oneof<nothing, bool> # Whether the URL is enabled. The default is `true`.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --priority: int # The relative importance of the URI. Can be an integer from 0 to 65535, inclusive, and the default is 10. The lowest number represents the most important URI.
  --sip-url: string # The SIP address you want Twilio to route your Origination calls to. This must be a `sip:` schema. `sips` is NOT supported. (format: uri)
  --weight: int # The value that determines the relative share of the load the URI should receive compared to other URIs with the same priority. Can be an integer from 1 to 65535, inclusive, and the default is 10. URLs with higher values receive more load than those with lower ones with the same priority.
]: any -> record<account_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, sip_url: string, trunk_sid: string, url: string, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{trunk_sid}/OriginationUrls/{sid}") $auth.query)
  let req_body = {"Enabled": $enabled, "FriendlyName": $friendly_name, "Priority": $priority, "SipUrl": $sip_url, "Weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# GET /v1/Trunks/{TrunkSid}/PhoneNumbers
#
# operationId: ListPhoneNumber
export def "trunks-phone-numbers list" [
  trunk_sid: string
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, phone_numbers: table<account_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record, date_created: string, date_updated: string, friendly_name: string, links: record, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, url: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/PhoneNumbers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Trunks/{TrunkSid}/PhoneNumbers
#
# operationId: CreatePhoneNumber
export def "trunks-phone-numbers create" [
  trunk_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number_sid: string # The SID of the [Incoming Phone Number](https://www.twilio.com/docs/phone-numbers/api/incomingphonenumber-resource) that you want to associate with the trunk.
]: any -> record<account_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record, date_created: string, date_updated: string, friendly_name: string, links: record, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, url: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/PhoneNumbers") $auth.query)
  let req_body = {"PhoneNumberSid": $phone_number_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Trunks/{TrunkSid}/PhoneNumbers/{Sid}
#
# operationId: DeletePhoneNumber
export def "trunks-phone-numbers delete" [
  trunk_sid: string
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
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{trunk_sid}/PhoneNumbers/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /v1/Trunks/{TrunkSid}/PhoneNumbers/{Sid}
#
# operationId: FetchPhoneNumber
export def "trunks-phone-numbers get" [
  trunk_sid: string
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
]: nothing -> record<account_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record, date_created: string, date_updated: string, friendly_name: string, links: record, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, url: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Trunks/{trunk_sid}/PhoneNumbers/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /v1/Trunks/{TrunkSid}/Recording
#
# operationId: FetchRecording
export def "trunks-recording get" [
  trunk_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<mode: string, trim: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/Recording") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Trunks/{TrunkSid}/Recording
#
# operationId: UpdateRecording
export def "trunks-recording update" [
  trunk_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer
  --trim: string@trim-completer
]: any -> record<mode: string, trim: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  if ($trunk_sid | is-empty) { error make --unspanned { msg: "path parameter 'TrunkSid' must be non-empty" } }
  let full_url = (build-url $base ({trunk_sid: (encode-path-segment $trunk_sid)} | format pattern "/v1/Trunks/{trunk_sid}/Recording") $auth.query)
  let req_body = {"Mode": $mode, "Trim": $trim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [202]
}
