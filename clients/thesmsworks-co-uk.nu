# Auto-generated client for The SMS Works API v1.8.0
# Source: https://api.apis.guru/v2/specs/thesmsworks.co.uk/1.8.0/swagger.json
# Auth: --token flag or $env.THE_SMS_WORKS_API_TOKEN

const BASE_URL = "https://api.thesmsworks.co.uk/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o THE_SMS_WORKS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.thesmsworks.co.uk/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "batch-any create" } } | get name | first)
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

# Sends a collection of unique SMS messages. Batches may contain up to 5000 messages at a time.
#
# POST /batch/any
export def "batch-any create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<batchid: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch/any" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Schedules a batch of SMS messages to be sent at the date time you specify
#
# POST /batch/schedule
export def "batch-schedule create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # Message to send to the recipient (e.g. My super awesome batch message)
  --deliveryreporturl: string # The url to which we should POST delivery reports to for this message. If none is specified, we'll use the global delivery report URL that you've configured on your account page. (e.g. http://your.domain.com/delivery/report/path)
  destinations: list<string> # Telephone numbers of each of the recipients (e.g. [447777777777, 447777777778, 447777777779])
  --schedule: string # Date-time at which to send the batch. This is only used by the batch/schedule service. (e.g. Wed Jul 19 2017 20:26:28 GMT+0100 (BST))
  sender: string # The sender of the message. Should be no longer than 11 characters for alphanumeric or 15 characters for numeric sender ID's. No spaces or special characters. (e.g. YourCompany)
  --tag: string # An identifying label for the message, which you can use to filter and report on messages you've sent later. Ideal for campaigns. A maximum of 280 characters. (e.g. SummerSpecial)
  --ttl: float # The number of minutes before the delivery report is deleted. Optional. Omit to prevent delivery report deletion. Integer. (e.g. 10)
  --validity: float # The optional number of minutes to attempt delivery before the message is marked as EXPIRED. Optional. The default is 2880 minutes. Integer. (e.g. 1440)
]: any -> record<batchid: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch/schedule" $auth.query)
  let req_body = {"content": $content, "deliveryreporturl": $deliveryreporturl, "destinations": $destinations, "schedule": $schedule, "sender": $sender, "tag": $tag, "ttl": $ttl, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Send a single SMS message to multiple recipients. Batches may contain up to 5000 messages at a time.
#
# POST /batch/send
export def "batch-send create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # Message to send to the recipient (e.g. My super awesome batch message)
  --deliveryreporturl: string # The url to which we should POST delivery reports to for this message. If none is specified, we'll use the global delivery report URL that you've configured on your account page. (e.g. http://your.domain.com/delivery/report/path)
  destinations: list<string> # Telephone numbers of each of the recipients (e.g. [447777777777, 447777777778, 447777777779])
  --schedule: string # Date-time at which to send the batch. This is only used by the batch/schedule service. (e.g. Wed Jul 19 2017 20:26:28 GMT+0100 (BST))
  sender: string # The sender of the message. Should be no longer than 11 characters for alphanumeric or 15 characters for numeric sender ID's. No spaces or special characters. (e.g. YourCompany)
  --tag: string # An identifying label for the message, which you can use to filter and report on messages you've sent later. Ideal for campaigns. A maximum of 280 characters. (e.g. SummerSpecial)
  --ttl: float # The number of minutes before the delivery report is deleted. Optional. Omit to prevent delivery report deletion. Integer. (e.g. 10)
  --validity: float # The optional number of minutes to attempt delivery before the message is marked as EXPIRED. Optional. The default is 2880 minutes. Integer. (e.g. 1440)
]: any -> record<batchid: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch/send" $auth.query)
  let req_body = {"content": $content, "deliveryreporturl": $deliveryreporturl, "destinations": $destinations, "schedule": $schedule, "sender": $sender, "tag": $tag, "ttl": $ttl, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve all messages in a batch with the given batch ID
#
# GET /batch/{batchid}
export def "batch get" [
  batchid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<batchid: string, content: string, created: string, customerid: string, deliveryreporturl: string, destination: float, failurereason: record<code: float, details: string, permanent: bool>, id: string, identifier: string, keyword: string, messageid: string, modified: string, schedule: string, sender: string, status: string, tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batchid | is-empty) { error make --unspanned { msg: "path parameter 'batchid' must be non-empty" } }
  let full_url = (build-url $base ({batchid: (encode-path-segment $batchid)} | format pattern "/batch/{batchid}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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

# Cancels a scheduled SMS message
#
# DELETE /batches/schedule/{batchid}
export def "batches-schedule delete" [
  batchid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<messageid: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batchid | is-empty) { error make --unspanned { msg: "path parameter 'batchid' must be non-empty" } }
  let full_url = (build-url $base ({batchid: (encode-path-segment $batchid)} | format pattern "/batches/schedule/{batchid}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns the number of credits currently available on the account
#
# GET /credits/balance
export def "credits-balance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<credits: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credits/balance" $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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

# Sends an SMS flash message, which appears on the recipients lock screen
#
# POST /message/flash
# operationId: sendFlashMessage
export def "message-flash send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # Message to send to the recipient. Content can be up to 1280 characters in length. Messages of 160 characters or fewer are charged 1 credit. If your message is longer than 160 characters then it will be broken down in to chunks of 153 characters before being sent to the recipient's handset, and you will be charged 1 credit for each 153 characters. Messages sent to numbers registered outside the UK will be typically charged double credits, but for certain countries may be charged fractions of credits (e.g. 2.5). Please contact us for rates for each country. (e.g. Your super awesome message)
  --deliveryreporturl: string # The url to which we should POST delivery reports to for this message. If none is specified, we'll use the global delivery report URL that you've configured on your account page. (e.g. http://your.domain.com/delivery/report/path)
  destination: string # Telephone number of the recipient (e.g. 447777777777)
  --metadata: list # e.g. [{key: myKey1, value: myValue1}, {key: myKey2, value: myValue2}]
  --responseemail: list<string> # An optional list of email addresses to forward responses to this specific message to. An SMS Works Reply Number is required to use this feature. (e.g. [my.email@mycompany.co.uk, my.other.email@mycompany.co.uk])
  --schedule: string # Date at which to send the message. This is only used by the message/schedule service and can be left empty for other services. (e.g. Sun Sep 03 2020 15:34:23 GMT+0100 (BST))
  sender: string # The sender of the message. Should be no longer than 11 characters for alphanumeric or 15 characters for numeric sender ID's. No spaces or special characters. (e.g. YourCompany)
  --tag: string # An identifying label for the message, which you can use to filter and report on messages you've sent later. Ideal for campaigns. A maximum of 280 characters. (e.g. SummerSpecial)
  --ttl: float # The optional number of minutes before the delivery report is deleted. Optional. Omit to prevent delivery report deletion. Integer. (e.g. 10)
  --validity: float # The optional number of minutes to attempt delivery before the message is marked as EXPIRED. Optional. The default is 2880 minutes. Integer. (e.g. 1440)
]: any -> record<credits: float, creditsUsed: float, messageid: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/message/flash" $auth.query)
  let req_body = {"content": $content, "deliveryreporturl": $deliveryreporturl, "destination": $destination, "metadata": $metadata, "responseemail": $responseemail, "schedule": $schedule, "sender": $sender, "tag": $tag, "ttl": $ttl, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Schedules an SMS message to be sent at the date-time you specify
#
# POST /message/schedule
export def "message-schedule create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # Message to send to the recipient. Content can be up to 1280 characters in length. Messages of 160 characters or fewer are charged 1 credit. If your message is longer than 160 characters then it will be broken down in to chunks of 153 characters before being sent to the recipient's handset, and you will be charged 1 credit for each 153 characters. Messages sent to numbers registered outside the UK will be typically charged double credits, but for certain countries may be charged fractions of credits (e.g. 2.5). Please contact us for rates for each country. (e.g. Your super awesome message)
  --deliveryreporturl: string # The url to which we should POST delivery reports to for this message. If none is specified, we'll use the global delivery report URL that you've configured on your account page. (e.g. http://your.domain.com/delivery/report/path)
  destination: string # Telephone number of the recipient (e.g. 447777777777)
  --metadata: list # e.g. [{key: myKey1, value: myValue1}, {key: myKey2, value: myValue2}]
  --responseemail: list<string> # An optional list of email addresses to forward responses to this specific message to. An SMS Works Reply Number is required to use this feature. (e.g. [my.email@mycompany.co.uk, my.other.email@mycompany.co.uk])
  --schedule: string # Date at which to send the message. This is only used by the message/schedule service and can be left empty for other services. (e.g. Sun Sep 03 2020 15:34:23 GMT+0100 (BST))
  sender: string # The sender of the message. Should be no longer than 11 characters for alphanumeric or 15 characters for numeric sender ID's. No spaces or special characters. (e.g. YourCompany)
  --tag: string # An identifying label for the message, which you can use to filter and report on messages you've sent later. Ideal for campaigns. A maximum of 280 characters. (e.g. SummerSpecial)
  --ttl: float # The optional number of minutes before the delivery report is deleted. Optional. Omit to prevent delivery report deletion. Integer. (e.g. 10)
  --validity: float # The optional number of minutes to attempt delivery before the message is marked as EXPIRED. Optional. The default is 2880 minutes. Integer. (e.g. 1440)
]: any -> table<messageid: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/message/schedule" $auth.query)
  let req_body = {"content": $content, "deliveryreporturl": $deliveryreporturl, "destination": $destination, "metadata": $metadata, "responseemail": $responseemail, "schedule": $schedule, "sender": $sender, "tag": $tag, "ttl": $ttl, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Send an SMS Message
#
# POST /message/send
export def "message-send create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # Message to send to the recipient. Content can be up to 1280 characters in length. Messages of 160 characters or fewer are charged 1 credit. If your message is longer than 160 characters then it will be broken down in to chunks of 153 characters before being sent to the recipient's handset, and you will be charged 1 credit for each 153 characters. Messages sent to numbers registered outside the UK will be typically charged double credits, but for certain countries may be charged fractions of credits (e.g. 2.5). Please contact us for rates for each country. (e.g. Your super awesome message)
  --deliveryreporturl: string # The url to which we should POST delivery reports to for this message. If none is specified, we'll use the global delivery report URL that you've configured on your account page. (e.g. http://your.domain.com/delivery/report/path)
  destination: string # Telephone number of the recipient (e.g. 447777777777)
  --metadata: list # e.g. [{key: myKey1, value: myValue1}, {key: myKey2, value: myValue2}]
  --responseemail: list<string> # An optional list of email addresses to forward responses to this specific message to. An SMS Works Reply Number is required to use this feature. (e.g. [my.email@mycompany.co.uk, my.other.email@mycompany.co.uk])
  --schedule: string # Date at which to send the message. This is only used by the message/schedule service and can be left empty for other services. (e.g. Sun Sep 03 2020 15:34:23 GMT+0100 (BST))
  sender: string # The sender of the message. Should be no longer than 11 characters for alphanumeric or 15 characters for numeric sender ID's. No spaces or special characters. (e.g. YourCompany)
  --tag: string # An identifying label for the message, which you can use to filter and report on messages you've sent later. Ideal for campaigns. A maximum of 280 characters. (e.g. SummerSpecial)
  --ttl: float # The optional number of minutes before the delivery report is deleted. Optional. Omit to prevent delivery report deletion. Integer. (e.g. 10)
  --validity: float # The optional number of minutes to attempt delivery before the message is marked as EXPIRED. Optional. The default is 2880 minutes. Integer. (e.g. 1440)
]: any -> record<credits: float, creditsUsed: float, messageid: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/message/send" $auth.query)
  let req_body = {"content": $content, "deliveryreporturl": $deliveryreporturl, "destination": $destination, "metadata": $metadata, "responseemail": $responseemail, "schedule": $schedule, "sender": $sender, "tag": $tag, "ttl": $ttl, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve up to 1000 messages matching your search criteria
#
# POST /messages
export def "messages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --credits: float # The number of credits used on the message. Floating point number. (e.g. 2)
  --destination: string # The phone number of the recipient. Start UK numbers with 44 and drop the leading 0. (e.g. 447777777777)
  --body-from: string # The date-time from which you would like matching messages (e.g. Wed Jul 12 2017 20:26:28 GMT+0100 (BST))
  --keyword: string # The keyword used in the inbound message (e.g. SKYWALKER)
  --limit: float # The maximum number of messages that you would like returned in this call. The default is 1000. (e.g. 1000)
  --metadata: list # An array of objects containing metadata key/value pairs that have been saved on messages. (e.g. [{key: myKey1, value: myValue1}, {key: myKey2, value: myValue2}])
  --sender: string # The sender of the message (this can be the configured sender name for an outbound message or the senders phone number for an inbound message). (e.g. YourCompany)
  --skip: float # The number of results you would like to ignore before returning messages. In combination with the 'limit' parameter his can be used to page results, so that you can deal with a limited number in your logic at each time. (e.g. 2000)
  --status: string # The status of the messages you would like returned (either 'SENT', 'DELIVERED', 'EXPIRED', 'UNDELIVERABLE', 'REJECTED' or 'INCOMING') (e.g. SENT)
  --body-to: string # The date-time to which you would like matching messages (e.g. Wed Jul 19 2017 20:26:28 GMT+0100 (BST))
  --unread: oneof<nothing, bool> # In queries for incoming messages ('status' is 'INCOMING'), specify whether you explicitly want unread messages (true) or read messages (false). Omit this parameter in other circumstances.
]: any -> table<batchid: string, content: string, created: string, customerid: string, deliveryreporturl: string, destination: float, failurereason: record<code: float, details: string, permanent: bool>, id: string, identifier: string, keyword: string, messageid: string, modified: string, schedule: string, sender: string, status: string, tag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages" $auth.query)
  let req_body = {"credits": $credits, "destination": $destination, "from": $body_from, "keyword": $keyword, "limit": $limit, "metadata": $metadata, "sender": $sender, "skip": $skip, "status": $status, "to": $body_to, "unread": $unread} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get failed messages matching your search criteria
#
# POST /messages/failed
export def "messages-failed create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --credits: float # The number of credits used on the message. Floating point number. (e.g. 2)
  --destination: string # The phone number of the recipient. Start UK numbers with 44 and drop the leading 0. (e.g. 447777777777)
  --body-from: string # The date-time from which you would like matching messages (e.g. Wed Jul 12 2017 20:26:28 GMT+0100 (BST))
  --keyword: string # The keyword used in the inbound message (e.g. SKYWALKER)
  --limit: float # The maximum number of messages that you would like returned in this call. The default is 1000. (e.g. 1000)
  --metadata: list # An array of objects containing metadata key/value pairs that have been saved on messages. (e.g. [{key: myKey1, value: myValue1}, {key: myKey2, value: myValue2}])
  --sender: string # The sender of the message (this can be the configured sender name for an outbound message or the senders phone number for an inbound message). (e.g. YourCompany)
  --skip: float # The number of results you would like to ignore before returning messages. In combination with the 'limit' parameter his can be used to page results, so that you can deal with a limited number in your logic at each time. (e.g. 2000)
  --status: string # The status of the messages you would like returned (either 'SENT', 'DELIVERED', 'EXPIRED', 'UNDELIVERABLE', 'REJECTED' or 'INCOMING') (e.g. SENT)
  --body-to: string # The date-time to which you would like matching messages (e.g. Wed Jul 19 2017 20:26:28 GMT+0100 (BST))
  --unread: oneof<nothing, bool> # In queries for incoming messages ('status' is 'INCOMING'), specify whether you explicitly want unread messages (true) or read messages (false). Omit this parameter in other circumstances.
]: any -> table<batchid: string, content: string, created: string, customerid: string, deliveryreporturl: string, destination: float, failurereason: record<code: float, details: string, permanent: bool>, id: string, identifier: string, keyword: string, messageid: string, modified: string, schedule: string, sender: string, status: string, tag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/failed" $auth.query)
  let req_body = {"credits": $credits, "destination": $destination, "from": $body_from, "keyword": $keyword, "limit": $limit, "metadata": $metadata, "sender": $sender, "skip": $skip, "status": $status, "to": $body_to, "unread": $unread} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get unread uncoming messages matching your search criteria
#
# POST /messages/inbox
export def "messages-inbox create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --credits: float # The number of credits used on the message. Floating point number. (e.g. 2)
  --destination: string # The phone number of the recipient. Start UK numbers with 44 and drop the leading 0. (e.g. 447777777777)
  --body-from: string # The date-time from which you would like matching messages (e.g. Wed Jul 12 2017 20:26:28 GMT+0100 (BST))
  --keyword: string # The keyword used in the inbound message (e.g. SKYWALKER)
  --limit: float # The maximum number of messages that you would like returned in this call. The default is 1000. (e.g. 1000)
  --metadata: list # An array of objects containing metadata key/value pairs that have been saved on messages. (e.g. [{key: myKey1, value: myValue1}, {key: myKey2, value: myValue2}])
  --sender: string # The sender of the message (this can be the configured sender name for an outbound message or the senders phone number for an inbound message). (e.g. YourCompany)
  --skip: float # The number of results you would like to ignore before returning messages. In combination with the 'limit' parameter his can be used to page results, so that you can deal with a limited number in your logic at each time. (e.g. 2000)
  --status: string # The status of the messages you would like returned (either 'SENT', 'DELIVERED', 'EXPIRED', 'UNDELIVERABLE', 'REJECTED' or 'INCOMING') (e.g. SENT)
  --body-to: string # The date-time to which you would like matching messages (e.g. Wed Jul 19 2017 20:26:28 GMT+0100 (BST))
  --unread: oneof<nothing, bool> # In queries for incoming messages ('status' is 'INCOMING'), specify whether you explicitly want unread messages (true) or read messages (false). Omit this parameter in other circumstances.
]: any -> table<batchid: string, content: string, created: string, customerid: string, deliveryreporturl: string, destination: float, failurereason: record<code: float, details: string, permanent: bool>, id: string, identifier: string, keyword: string, messageid: string, modified: string, schedule: string, sender: string, status: string, tag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/inbox" $auth.query)
  let req_body = {"credits": $credits, "destination": $destination, "from": $body_from, "keyword": $keyword, "limit": $limit, "metadata": $metadata, "sender": $sender, "skip": $skip, "status": $status, "to": $body_to, "unread": $unread} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of messages scheduled from your account, comprising any messages scheduled in the last 3 months and any scheduled to send in the future
#
# GET /messages/schedule
export def "messages-schedule get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<batch: bool, id: string, message: record<schema: record<content: string, destination: string, destinations: list, schedule: string, sender: string>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/schedule" $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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

# Cancels a scheduled SMS message
#
# DELETE /messages/schedule/{messageid}
export def "messages-schedule delete" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<messageid: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/schedule/{messageid}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Delete the message with the mathcing messageid
#
# DELETE /messages/{messageid}
export def "messages delete" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<messageid: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/{messageid}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve a logged message by the message ID
#
# GET /messages/{messageid}
export def "messages get" [
  messageid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<batchid: string, content: string, created: string, customerid: string, deliveryreporturl: string, destination: float, failurereason: record<code: float, details: string, permanent: bool>, id: string, identifier: string, keyword: string, messageid: string, modified: string, schedule: string, sender: string, status: string, tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($messageid | is-empty) { error make --unspanned { msg: "path parameter 'messageid' must be non-empty" } }
  let full_url = (build-url $base ({messageid: (encode-path-segment $messageid)} | format pattern "/messages/{messageid}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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

# Returns a sample error object for the given error code. Useful for designing code to react to errors when they occur for real.
#
# GET /utils/errors/{errorcode}
export def "utils-errors get" [
  errorcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, errorCode: float, permanent: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($errorcode | is-empty) { error make --unspanned { msg: "path parameter 'errorcode' must be non-empty" } }
  let full_url = (build-url $base ({errorcode: (encode-path-segment $errorcode)} | format pattern "/utils/errors/{errorcode}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns the customer ID to the caller
#
# GET /utils/test
export def "utils-test get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/utils/test" $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
