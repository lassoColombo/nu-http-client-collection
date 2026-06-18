# Auto-generated client for Amazon Connect Participant Service v2018-09-07
# Source: https://api.apis.guru/v2/specs/amazonaws.com/connectparticipant/2018-09-07/openapi.json
# Auth: --token flag or $env.AMAZON_CONNECT_PARTICIPANT_SERVICE_TOKEN

const BASE_URL = "http://participant.connect.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_CONNECT_PARTICIPANT_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://participant.connect.us-east-1.amazonaws.com" "http://participant.connect.us-east-2.amazonaws.com" "http://participant.connect.us-west-1.amazonaws.com" "http://participant.connect.us-west-2.amazonaws.com" "http://participant.connect.us-gov-west-1.amazonaws.com" "http://participant.connect.us-gov-east-1.amazonaws.com" "http://participant.connect.ca-central-1.amazonaws.com" "http://participant.connect.eu-north-1.amazonaws.com" "http://participant.connect.eu-west-1.amazonaws.com" "http://participant.connect.eu-west-2.amazonaws.com" "http://participant.connect.eu-west-3.amazonaws.com" "http://participant.connect.eu-central-1.amazonaws.com" "http://participant.connect.eu-south-1.amazonaws.com" "http://participant.connect.af-south-1.amazonaws.com" "http://participant.connect.ap-northeast-1.amazonaws.com" "http://participant.connect.ap-northeast-2.amazonaws.com" "http://participant.connect.ap-northeast-3.amazonaws.com" "http://participant.connect.ap-southeast-1.amazonaws.com" "http://participant.connect.ap-southeast-2.amazonaws.com" "http://participant.connect.ap-east-1.amazonaws.com" "http://participant.connect.ap-south-1.amazonaws.com" "http://participant.connect.sa-east-1.amazonaws.com" "http://participant.connect.me-south-1.amazonaws.com" "https://participant.connect.us-east-1.amazonaws.com" "https://participant.connect.us-east-2.amazonaws.com" "https://participant.connect.us-west-1.amazonaws.com" "https://participant.connect.us-west-2.amazonaws.com" "https://participant.connect.us-gov-west-1.amazonaws.com" "https://participant.connect.us-gov-east-1.amazonaws.com" "https://participant.connect.ca-central-1.amazonaws.com" "https://participant.connect.eu-north-1.amazonaws.com" "https://participant.connect.eu-west-1.amazonaws.com" "https://participant.connect.eu-west-2.amazonaws.com" "https://participant.connect.eu-west-3.amazonaws.com" "https://participant.connect.eu-central-1.amazonaws.com" "https://participant.connect.eu-south-1.amazonaws.com" "https://participant.connect.af-south-1.amazonaws.com" "https://participant.connect.ap-northeast-1.amazonaws.com" "https://participant.connect.ap-northeast-2.amazonaws.com" "https://participant.connect.ap-northeast-3.amazonaws.com" "https://participant.connect.ap-southeast-1.amazonaws.com" "https://participant.connect.ap-southeast-2.amazonaws.com" "https://participant.connect.ap-east-1.amazonaws.com" "https://participant.connect.ap-south-1.amazonaws.com" "https://participant.connect.sa-east-1.amazonaws.com" "https://participant.connect.me-south-1.amazonaws.com" "http://participant.connect.cn-north-1.amazonaws.com.cn" "http://participant.connect.cn-northwest-1.amazonaws.com.cn" "https://participant.connect.cn-north-1.amazonaws.com.cn" "https://participant.connect.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def scan-direction-completer [] { ["BACKWARD" "FORWARD"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "participant-complete-attachment-upload-x-amz-bearer upload" } } | get name | first)
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

# Allows you to confirm that the attachment has been uploaded using the pre-signed URL provided in StartAttachmentUpload API. ConnectionToken is used for invoking this API instead of ParticipantToken. The Amazon Connect Participant Service APIs do not use Signature Version 4 authentication (https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).
#
# POST /participant/complete-attachment-upload#X-Amz-Bearer
# operationId: CompleteAttachmentUpload
export def "participant-complete-attachment-upload-x-amz-bearer upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-bearer: string # The authentication token associated with the participant's connection.
  attachment_ids: list<string> # A list of unique identifiers for the attachments.
  client_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/participant/complete-attachment-upload#X-Amz-Bearer")
  let req_body = {"AttachmentIds": $attachment_ids, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Bearer": $x_amz_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates the participant's connection. ParticipantToken is used for invoking this API instead of ConnectionToken. The participant token is valid for the lifetime of the participant – until they are part of a contact. The response URL for WEBSOCKET Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. For chat, you need to publish the following on the established websocket connection: {"topic":"aws/subscribe","content":{"topics":["aws/chat"]}} Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before. Message streaming support: This API can also be used together with the StartContactStreaming (https://docs.aws.amazon.com/connect/latest/APIReference/API_StartContactStreaming.html) API to create a participant connection for chat contacts that are not using a websocket. For more information about message streaming, Enable real-time chat message streaming (https://docs.aws.amazon.com/connect/latest/adminguide/chat-message-streaming.html) in the Amazon Connect Administrator Guide. Feature specifications: For information about feature specifications, such as the allowed number of open websocket connections per participant, see Feature specifications (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html#feature-limits) in the Amazon Connect Administrator Guide. The Amazon Connect Participant Service APIs do not use Signature Version 4 authentication (https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).
#
# POST /participant/connection#X-Amz-Bearer
# operationId: CreateParticipantConnection
export def "participant-connection-x-amz-bearer create-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-bearer: string # This is a header parameter. The ParticipantToken as obtained from StartChatContact (https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContact.html) API response.
  --type: list<string> # Type of connection information required. This can be omitted if ConnectParticipant is true.
  --connect-participant: oneof<nothing, bool> # Amazon Connect Participant is used to mark the participant as connected for customer participant in message streaming, as well as for agent or manager participant in non-streaming chats.
]: any -> record<Websocket: record<Url: record, ConnectionExpiry: record>, ConnectionCredentials: record<ConnectionToken: record, Expiry: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/participant/connection#X-Amz-Bearer")
  let req_body = {"Type": $type, "ConnectParticipant": $connect_participant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Bearer": $x_amz_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disconnects a participant. ConnectionToken is used for invoking this API instead of ParticipantToken. The Amazon Connect Participant Service APIs do not use Signature Version 4 authentication (https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).
#
# POST /participant/disconnect#X-Amz-Bearer
# operationId: DisconnectParticipant
export def "participant-disconnect-x-amz-bearer create-disconnect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-bearer: string # The authentication token associated with the participant's connection.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/participant/disconnect#X-Amz-Bearer")
  let req_body = {"ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Bearer": $x_amz_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides a pre-signed URL for download of a completed attachment. This is an asynchronous API for use with active contacts. ConnectionToken is used for invoking this API instead of ParticipantToken. The Amazon Connect Participant Service APIs do not use Signature Version 4 authentication (https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).
#
# POST /participant/attachment#X-Amz-Bearer
# operationId: GetAttachment
export def "participant-attachment-x-amz-bearer get-attachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-bearer: string # The authentication token associated with the participant's connection.
  attachment_id: string # A unique identifier for the attachment.
]: any -> record<Url: record, UrlExpiry: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/participant/attachment#X-Amz-Bearer")
  let req_body = {"AttachmentId": $attachment_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Bearer": $x_amz_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a transcript of the session, including details about any attachments. For information about accessing past chat contact transcripts for a persistent chat, see Enable persistent chat (https://docs.aws.amazon.com/connect/latest/adminguide/chat-persistence.html). ConnectionToken is used for invoking this API instead of ParticipantToken. The Amazon Connect Participant Service APIs do not use Signature Version 4 authentication (https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).
#
# POST /participant/transcript#X-Amz-Bearer
# operationId: GetTranscript
# --StartPosition shape: {Id?: any, AbsoluteTime?: any, MostRecent?: any}
export def "participant-transcript-x-amz-bearer get-transcript" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-bearer: string # The authentication token associated with the participant's connection.
  --contact-id: string # The contactId from the current contact chain for which transcript is needed.
  --max-results: int # The maximum number of results to return in the page. Default: 10.
  --next-token: string # The pagination token. Use the value returned previously in the next subsequent request to retrieve the next set of results.
  --scan-direction: string@scan-direction-completer # The direction from StartPosition from which to retrieve message. Default: BACKWARD when no StartPosition is provided, FORWARD with StartPosition.
  --sort-order: string@sort-order-completer # The sort order for the records. Default: DESCENDING.
  --start-position: record # A filtering option for where to start. For example, if you sent 100 messages, start with message 50. — shape: {Id?: any, AbsoluteTime?: any, MostRecent?: any}
]: any -> record<InitialContactId: record, Transcript: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/participant/transcript#X-Amz-Bearer" $qp)
  let req_body = {"ContactId": $contact_id, "MaxResults": $max_results, "NextToken": $next_token, "ScanDirection": $scan_direction, "SortOrder": $sort_order, "StartPosition": $start_position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Bearer": $x_amz_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Sends an event. ConnectionToken is used for invoking this API instead of ParticipantToken. The Amazon Connect Participant Service APIs do not use Signature Version 4 authentication (https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).
#
# POST /participant/event#X-Amz-Bearer
# operationId: SendEvent
export def "participant-event-x-amz-bearer send-event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-bearer: string # The authentication token associated with the participant's connection.
  content_type: string # The content type of the request. Supported types are: application/vnd.amazonaws.connect.event.typing application/vnd.amazonaws.connect.event.connection.acknowledged application/vnd.amazonaws.connect.event.message.delivered application/vnd.amazonaws.connect.event.message.read
  --content: string # The content of the event to be sent (for example, message text). For content related to message receipts, this is supported in the form of a JSON string. Sample Content: "{\"messageId\":\"11111111-aaaa-bbbb-cccc-EXAMPLE01234\"}"
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<Id: record, AbsoluteTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/participant/event#X-Amz-Bearer")
  let req_body = {"ContentType": $content_type, "Content": $content, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Bearer": $x_amz_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Sends a message. ConnectionToken is used for invoking this API instead of ParticipantToken. The Amazon Connect Participant Service APIs do not use Signature Version 4 authentication (https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).
#
# POST /participant/message#X-Amz-Bearer
# operationId: SendMessage
export def "participant-message-x-amz-bearer send-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-bearer: string # The authentication token associated with the connection.
  content_type: string # The type of the content. Supported types are text/plain, text/markdown, application/json, and application/vnd.amazonaws.connect.message.interactive.response.
  content: string # The content of the message. For text/plain and text/markdown, the Length Constraints are Minimum of 1, Maximum of 1024. For application/json, the Length Constraints are Minimum of 1, Maximum of 12000. For application/vnd.amazonaws.connect.message.interactive.response, the Length Constraints are Minimum of 1, Maximum of 12288.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<Id: record, AbsoluteTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/participant/message#X-Amz-Bearer")
  let req_body = {"ContentType": $content_type, "Content": $content, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Bearer": $x_amz_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides a pre-signed Amazon S3 URL in response for uploading the file directly to S3. ConnectionToken is used for invoking this API instead of ParticipantToken. The Amazon Connect Participant Service APIs do not use Signature Version 4 authentication (https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).
#
# POST /participant/start-attachment-upload#X-Amz-Bearer
# operationId: StartAttachmentUpload
export def "participant-start-attachment-upload-x-amz-bearer upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-bearer: string # The authentication token associated with the participant's connection.
  content_type: string # Describes the MIME file type of the attachment. For a list of supported file types, see Feature specifications (https://docs.aws.amazon.com/connect/latest/adminguide/feature-limits.html) in the Amazon Connect Administrator Guide.
  attachment_size_in_bytes: int # The size of the attachment in bytes.
  attachment_name: string # A case-sensitive name of the attachment being uploaded.
  client_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<AttachmentId: record, UploadMetadata: record<Url: record, UrlExpiry: record, HeadersToInclude: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/participant/start-attachment-upload#X-Amz-Bearer")
  let req_body = {"ContentType": $content_type, "AttachmentSizeInBytes": $attachment_size_in_bytes, "AttachmentName": $attachment_name, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Bearer": $x_amz_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
