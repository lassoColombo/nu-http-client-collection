# Auto-generated client for Amazon Chime v2018-05-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/chime/2018-05-01/openapi.json
# Auth: --token flag or $env.AMAZON_CHIME_TOKEN

const BASE_URL = "http://service.chime.aws.amazon.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_CHIME_TOKEN | default "" }
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

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://service.chime.aws.amazon.com" "https://service.chime.aws.amazon.com" "http://chime.cn-north-1.amazonaws.com.cn" "http://chime.cn-northwest-1.amazonaws.com.cn" "https://chime.cn-north-1.amazonaws.com.cn" "https://chime.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def operation-completer [] { ["associate-phone-number"] }
def operation-completer-1 [] { ["associate-phone-numbers"] }
def operation-completer-2 [] { ["associate-signin-delegate-groups"] }
def operation-completer-3 [] { ["batch-create"] }
def type-completer [] { ["DEFAULT" "HIDDEN"] }
def operation-completer-4 [] { ["batch-delete"] }
def operation-completer-5 [] { ["suspend"] }
def operation-completer-6 [] { ["unsuspend"] }
def operation-completer-7 [] { ["batch-update"] }
def user-type-completer [] { ["PrivateUser" "SharedDevice"] }
def mode-completer [] { ["RESTRICTED" "UNRESTRICTED"] }
def privacy-completer [] { ["PRIVATE" "PUBLIC"] }
def source-type-completer [] { ["ChimeSdkMeeting"] }
def sink-type-completer [] { ["S3Bucket"] }
def operation-completer-8 [] { ["create-attendees"] }
def product-type-completer [] { ["BusinessCalling" "SipMediaApplicationDialIn" "VoiceConnector"] }
def number-selection-behavior-completer [] { ["AvoidSticky" "PreferSticky"] }
def geo-match-level-completer [] { ["AreaCode" "Country"] }
def status-completer [] { ["Closed" "InProgress" "Open"] }
def role-completer [] { ["Administrator" "Member"] }
def trigger-type-completer [] { ["RequestUriHostname" "ToPhoneNumber"] }
def operation-completer-9 [] { ["create"] }
def aws-region-completer [] { ["us-east-1" "us-west-2"] }
def default-license-completer [] { ["Basic" "Plus" "Pro" "ProTrial"] }
def operation-completer-10 [] { ["delete"] }
def scope-completer [] { ["app-instance-user-membership"] }
def scope-completer-1 [] { ["app-instance-user-moderated-channel"] }
def operation-completer-11 [] { ["disassociate-phone-number"] }
def operation-completer-12 [] { ["disassociate-phone-numbers"] }
def operation-completer-13 [] { ["disassociate-signin-delegate-groups"] }
def license-type-completer [] { ["Basic" "Plus" "Pro" "ProTrial"] }
def operation-completer-14 [] { ["add"] }
def scope-completer-2 [] { ["app-instance-user-memberships"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def type-completer-1 [] { ["CONTROL" "STANDARD"] }
def persistence-completer [] { ["NON_PERSISTENT" "PERSISTENT"] }
def scope-completer-3 [] { ["app-instance-user-moderated-channels"] }
def status-completer-1 [] { ["AcquireFailed" "AcquireInProgress" "Assigned" "DeleteFailed" "DeleteInProgress" "ReleaseFailed" "ReleaseInProgress" "Unassigned"] }
def filter-name-completer [] { ["AccountId" "SipRuleId" "UserId" "VoiceConnectorGroupId" "VoiceConnectorId"] }
def operation-completer-15 [] { ["logout"] }
def operation-completer-16 [] { ["put"] }
def operation-completer-17 [] { ["redact"] }
def operation-completer-18 [] { ["regenerate-security-token"] }
def operation-completer-19 [] { ["reset-personal-pin"] }
def operation-completer-20 [] { ["restore"] }
def phone-number-type-completer [] { ["Local" "TollFree"] }
def type-completer-2 [] { ["phone-numbers"] }
def operation-completer-21 [] { ["start"] }
def operation-completer-22 [] { ["stop"] }
def operation-completer-23 [] { ["tag-resource"] }
def operation-completer-24 [] { ["untag-resource"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-users create-associate-phone-number" } } | get name | first)
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

# Associates a phone number with the specified Amazon Chime user.
#
# POST /accounts/{accountId}/users/{userId}
# operationId: AssociatePhoneNumberWithUser
export def "accounts-users create-associate-phone-number" [
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_number: string # The phone number, in E.164 format. (format: password)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), user_id: (encode-path-segment $user_id)} | format pattern "/accounts/{account_id}/users/{user_id}") $qp $auth.query)
  let req_body = {"E164PhoneNumber": $e164_phone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Associates phone numbers with the specified Amazon Chime Voice Connector.
#
# POST /voice-connectors/{voiceConnectorId}
# operationId: AssociatePhoneNumbersWithVoiceConnector
export def "voice-connectors create-associate-phone-numbers" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-1
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
  --force-associate: oneof<nothing, bool> # If true, associates the provided phone numbers with the provided Amazon Chime Voice Connector and removes any previously existing associations. If false, does not associate any phone numbers that have previously existing associations.
]: any -> record<PhoneNumberErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}") $qp $auth.query)
  let req_body = {"E164PhoneNumbers": $e164_phone_numbers, "ForceAssociate": $force_associate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Associates phone numbers with the specified Amazon Chime Voice Connector group.
#
# POST /voice-connector-groups/{voiceConnectorGroupId}
# operationId: AssociatePhoneNumbersWithVoiceConnectorGroup
export def "voice-connector-groups create-associate-phone-numbers" [
  voice_connector_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-1
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
  --force-associate: oneof<nothing, bool> # If true, associates the provided phone numbers with the provided Amazon Chime Voice Connector Group and removes any previously existing associations. If false, does not associate any phone numbers that have previously existing associations.
]: any -> record<PhoneNumberErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_group_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorGroupId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({voice_connector_group_id: (encode-path-segment $voice_connector_group_id)} | format pattern "/voice-connector-groups/{voice_connector_group_id}") $qp $auth.query)
  let req_body = {"E164PhoneNumbers": $e164_phone_numbers, "ForceAssociate": $force_associate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Associates the specified sign-in delegate groups with the specified Amazon Chime account.
#
# POST /accounts/{accountId}
# operationId: AssociateSigninDelegateGroupsWithAccount
# --SigninDelegateGroups item shape: {GroupName?: any}
export def "accounts create-associate-signin-delegate-groups" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-2
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  signin_delegate_groups: list # The sign-in delegate groups. — item shape: {GroupName?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $qp $auth.query)
  let req_body = {"SigninDelegateGroups": $signin_delegate_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# POST /meetings/{meetingId}/attendees
# operationId: BatchCreateAttendee
# --Attendees item shape: {ExternalUserId: any, Tags?: any}
export def "meetings-attendees create-batch" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-3
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  attendees: list # The request containing the attendees to create. — item shape: {ExternalUserId: any, Tags?: any}
]: any -> record<Attendees: record, Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/attendees") $qp $auth.query)
  let req_body = {"Attendees": $attendees} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Adds a specified number of users to a channel.
#
# POST /channels/{channelArn}/memberships
# operationId: BatchCreateChannelMembership
export def "channels-memberships create-batch" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-3
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  --type: string@type-completer # The membership type of a user, DEFAULT or HIDDEN. Default members are always returned as part of ListChannelMemberships. Hidden members are only returned if the type filter in ListChannelMemberships equals HIDDEN. Otherwise hidden members are not returned. This is only supported by moderators.
  member_arns: list<string> # The ARNs of the members you want to add to the channel.
]: any -> record<BatchChannelMemberships: record<InvitedBy: record<Arn: record, Name: record>, Type: record, Members: record, ChannelArn: record>, Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/memberships") $qp $auth.query)
  let req_body = {"Type": $type, "MemberArns": $member_arns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Adds up to 50 members to a chat room in an Amazon Chime Enterprise account. Members can be users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
#
# POST /accounts/{accountId}/rooms/{roomId}/memberships
# operationId: BatchCreateRoomMembership
# --MembershipItemList item shape: {MemberId?: any, Role?: any}
export def "accounts-rooms-memberships create-batch" [
  account_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-3
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  membership_item_list: list # The list of membership items. — item shape: {MemberId?: any, Role?: any}
]: any -> record<Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), room_id: (encode-path-segment $room_id)} | format pattern "/accounts/{account_id}/rooms/{room_id}/memberships") $qp $auth.query)
  let req_body = {"MembershipItemList": $membership_item_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Moves phone numbers into the Deletion queue. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted. Phone numbers remain in the Deletion queue for 7 days before they are deleted permanently.
#
# POST /phone-numbers
# operationId: BatchDeletePhoneNumber
export def "phone-numbers delete-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-4
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  phone_number_ids: list<string> # List of phone number IDs.
]: any -> record<PhoneNumberErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone-numbers" $qp $auth.query)
  let req_body = {"PhoneNumberIds": $phone_number_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Suspends up to 50 users from a Team or EnterpriseLWA Amazon Chime account. For more information about different account types, see Managing Your Amazon Chime Accounts (https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html) in the Amazon Chime Administration Guide. Users suspended from a Team account are disassociated from the account,but they can continue to use Amazon Chime as free users. To remove the suspension from suspended Team account users, invite them to the Team account again. You can use the InviteUsers action to do so. Users suspended from an EnterpriseLWA account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended EnterpriseLWA account users, use the BatchUnsuspendUser action. To sign out users without suspending them, use the LogoutUser action.
#
# POST /accounts/{accountId}/users
# operationId: BatchSuspendUser
export def "accounts-users create-batch-suspend" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-5
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  user_id_list: list<string> # The request containing the user IDs to suspend.
]: any -> record<UserErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/users") $qp $auth.query)
  let req_body = {"UserIdList": $user_id_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime EnterpriseLWA account. Only users on EnterpriseLWA accounts can be unsuspended using this action. For more information about different account types, see Managing Your Amazon Chime Accounts (https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html) in the account types, in the Amazon Chime Administration Guide. Previously suspended users who are unsuspended using this action are returned to Registered status. Users who are not previously suspended are ignored.
#
# POST /accounts/{accountId}/users
# operationId: BatchUnsuspendUser
export def "accounts-users create-batch-unsuspend" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-6
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  user_id_list: list<string> # The request containing the user IDs to unsuspend.
]: any -> record<UserErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/users") $qp $auth.query)
  let req_body = {"UserIdList": $user_id_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates phone number product types or calling names. You can update one attribute at a time for each UpdatePhoneNumberRequestItem. For example, you can update the product type or the calling name. For toll-free numbers, you cannot use the Amazon Chime Business Calling product type. For numbers outside the U.S., you must use the Amazon Chime SIP Media Application Dial-In product type. Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.
#
# POST /phone-numbers
# operationId: BatchUpdatePhoneNumber
# --UpdatePhoneNumberRequestItems item shape: {PhoneNumberId: any, ProductType?: any, CallingName?: any}
export def "phone-numbers update-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-7
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  update_phone_number_request_items: list # The request containing the phone number IDs and product types or calling names to update. — item shape: {PhoneNumberId: any, ProductType?: any, CallingName?: any}
]: any -> record<PhoneNumberErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone-numbers" $qp $auth.query)
  let req_body = {"UpdatePhoneNumberRequestItems": $update_phone_number_request_items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates user details within the UpdateUserRequestItem object for up to 20 users for the specified Amazon Chime account. Currently, only LicenseType updates are supported for this action.
#
# POST /accounts/{accountId}/users
# operationId: BatchUpdateUser
# --UpdateUserRequestItems item shape: {UserId: any, LicenseType?: any, UserType?: any, AlexaForBusinessMetadata?: any}
export def "accounts-users update-batch" [
  account_id: string
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
  update_user_request_items: list # The request containing the user IDs and details to update. — item shape: {UserId: any, LicenseType?: any, UserType?: any, AlexaForBusinessMetadata?: any}
]: any -> record<UserErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/users") $auth.query)
  let req_body = {"UpdateUserRequestItems": $update_user_request_items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
#
# GET /accounts/{accountId}/users
# operationId: ListUsers
export def "accounts-users list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-email: string # Optional. The user email address used to filter results. Maximum 1. (format: password)
  --user-type: string@user-type-completer # The user type.
  --max-results: int # The maximum number of results to return in a single call. Defaults to 100.
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Users: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "user-email" $user_email "scalar") (serialize-qp "user-type" $user_type "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/users") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"user-email": $user_email, "user-type": $user_type, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates an Amazon Chime account under the administrator's AWS account. Only Team account types are currently supported for this action. For more information about different account types, see Managing Your Amazon Chime Accounts (https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html) in the Amazon Chime Administration Guide.
#
# POST /accounts
# operationId: CreateAccount
export def "accounts create" [
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
  name: string # The name of the Amazon Chime account.
]: any -> record<Account: record<AwsAccountId: record, AccountId: record, Name: record, AccountType: record, CreatedTimestamp: record, DefaultLicense: record, SupportedLicenses: record, AccountStatus: record, SigninDelegateGroups: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts" $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
#
# GET /accounts
# operationId: ListAccounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Amazon Chime account name prefix with which to filter results.
  --user-email: string # User email address with which to filter results. (format: password)
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call. Defaults to 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Accounts: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "user-email" $user_email "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "user-email": $user_email, "next-token": $next_token, "max-results": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates an Amazon Chime SDK messaging AppInstance under an AWS account. Only SDK messaging customers use this API. CreateAppInstance supports idempotency behavior as described in the AWS API Standard.
#
# POST /app-instances
# operationId: CreateAppInstance
# --Tags item shape: {Key: any, Value: any}
export def "app-instances create" [
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
  name: string # The name of the AppInstance. (format: password)
  --metadata: string # The metadata of the AppInstance. Limited to a 1KB string in UTF-8. (format: password)
  client_request_token: string # The ClientRequestToken of the AppInstance. (format: password)
  --tags: list # Tags assigned to the AppInstance. — item shape: {Key: any, Value: any}
]: any -> record<AppInstanceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app-instances" $auth.query)
  let req_body = {"Name": $name, "Metadata": $metadata, "ClientRequestToken": $client_request_token, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists all Amazon Chime AppInstances created under a single AWS account.
#
# GET /app-instances
# operationId: ListAppInstances
export def "app-instances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of AppInstances that you want to return.
  --next-token: string # The token passed by previous API requests until you reach the maximum number of AppInstances. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AppInstances: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/app-instances" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Promotes an AppInstanceUser to an AppInstanceAdmin. The promoted user can perform the following actions. ChannelModerator actions across all channels in the AppInstance. DeleteChannelMessage actions. Only an AppInstanceUser can be promoted to an AppInstanceAdmin role.
#
# POST /app-instances/{appInstanceArn}/admins
# operationId: CreateAppInstanceAdmin
export def "app-instances-admins create" [
  app_instance_arn: string
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
  app_instance_admin_arn: string # The ARN of the administrator of the current AppInstance.
]: any -> record<AppInstanceAdmin: record<Arn: record, Name: record>, AppInstanceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}/admins") $auth.query)
  let req_body = {"AppInstanceAdminArn": $app_instance_admin_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns a list of the administrators in the AppInstance.
#
# GET /app-instances/{appInstanceArn}/admins
# operationId: ListAppInstanceAdmins
export def "app-instances-admins list" [
  app_instance_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of administrators that you want to return.
  --next-token: string # The token returned from previous API requests until the number of administrators is reached. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AppInstanceArn: record, AppInstanceAdmins: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let qp = [(serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}/admins") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a user under an Amazon Chime AppInstance. The request consists of a unique appInstanceUserId and Name for that user.
#
# POST /app-instance-users
# operationId: CreateAppInstanceUser
# --Tags item shape: {Key: any, Value: any}
export def "app-instance-users create" [
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
  app_instance_arn: string # The ARN of the AppInstance request.
  app_instance_user_id: string # The user ID of the AppInstance. (format: password)
  name: string # The user's name. (format: password)
  --metadata: string # The request's metadata. Limited to a 1KB string in UTF-8. (format: password)
  client_request_token: string # The token assigned to the user requesting an AppInstance. (format: password)
  --tags: list # Tags assigned to the AppInstanceUser. — item shape: {Key: any, Value: any}
]: any -> record<AppInstanceUserArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app-instance-users" $auth.query)
  let req_body = {"AppInstanceArn": $app_instance_arn, "AppInstanceUserId": $app_instance_user_id, "Name": $name, "Metadata": $metadata, "ClientRequestToken": $client_request_token, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# POST /meetings/{meetingId}/attendees
# operationId: CreateAttendee
# --Tags item shape: {Key: any, Value: any}
export def "meetings-attendees create" [
  meeting_id: string
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
  external_user_id: string # The Amazon Chime SDK external user ID. An idempotency token. Links the attendee to an identity managed by a builder application. (format: password)
  --tags: list # The tag key-value pairs. — item shape: {Key: any, Value: any}
]: any -> record<Attendee: record<ExternalUserId: record, AttendeeId: record, JoinToken: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/attendees") $auth.query)
  let req_body = {"ExternalUserId": $external_user_id, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# GET /meetings/{meetingId}/attendees
# operationId: ListAttendees
export def "meetings-attendees list" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Attendees: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/attendees") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next-token": $next_token, "max-results": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a bot for an Amazon Chime Enterprise account.
#
# POST /accounts/{accountId}/bots
# operationId: CreateBot
export def "accounts-bots create" [
  account_id: string
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
  display_name: string # The bot display name. (format: password)
  --domain: string # The domain of the Amazon Chime Enterprise account.
]: any -> record<Bot: record<BotId: record, UserId: record, DisplayName: record, BotType: record, Disabled: record, CreatedTimestamp: record, UpdatedTimestamp: record, BotEmail: record, SecurityToken: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/bots") $auth.query)
  let req_body = {"DisplayName": $display_name, "Domain": $domain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
#
# GET /accounts/{accountId}/bots
# operationId: ListBots
export def "accounts-bots list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in a single call. The default is 10.
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Bots: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/bots") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a channel to which you can add users and send messages. Restriction: You can't change a channel's privacy. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels
# operationId: CreateChannel
# --Tags item shape: {Key: any, Value: any}
export def "channels create" [
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  app_instance_arn: string # The ARN of the channel request.
  name: string # The name of the channel. (format: password)
  --mode: string@mode-completer # The channel mode: UNRESTRICTED or RESTRICTED. Administrators, moderators, and channel members can add themselves and other members to unrestricted channels. Only administrators and moderators can add members to restricted channels.
  --privacy: string@privacy-completer # The channel's privacy level: PUBLIC or PRIVATE. Private channels aren't discoverable by users outside the channel. Public channels are discoverable by anyone in the AppInstance.
  --metadata: string # The metadata of the creation request. Limited to 1KB and UTF-8. (format: password)
  client_request_token: string # The client token for the request. An Idempotency token. (format: password)
  --tags: list # The tags for the creation request. — item shape: {Key: any, Value: any}
]: any -> record<ChannelArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels" $auth.query)
  let req_body = {"AppInstanceArn": $app_instance_arn, "Name": $name, "Mode": $mode, "Privacy": $privacy, "Metadata": $metadata, "ClientRequestToken": $client_request_token, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Permanently bans a member from a channel. Moderators can't add banned members to a channel. To undo a ban, you first have to DeleteChannelBan, and then CreateChannelMembership. Bans are cleaned up when you delete users or channels. If you ban a user who is already part of a channel, that user is automatically kicked from the channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels/{channelArn}/bans
# operationId: CreateChannelBan
export def "channels-bans create" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  member_arn: string # The ARN of the member being banned.
]: any -> record<ChannelArn: record, Member: record<Arn: record, Name: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/bans") $auth.query)
  let req_body = {"MemberArn": $member_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists all the users banned from a particular channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/bans
# operationId: ListChannelBans
export def "channels-bans list" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of bans that you want returned.
  --next-token: string # The token passed by previous API calls until all requested bans are returned. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelArn: record, NextToken: record, ChannelBans: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let qp = [(serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/bans") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a user to a channel. The InvitedBy response field is derived from the request header. A channel member can: List messages Send messages Receive messages Edit their own messages Leave the channel Privacy settings impact this action as follows: Public Channels: You do not need to be a member to list messages, but you must be a member to send messages. Private Channels: You must be a member to list or send messages. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels/{channelArn}/memberships
# operationId: CreateChannelMembership
export def "channels-memberships create" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  member_arn: string # The ARN of the member you want to add to the channel.
  type: string@type-completer # The membership type of a user, DEFAULT or HIDDEN. Default members are always returned as part of ListChannelMemberships. Hidden members are only returned if the type filter in ListChannelMemberships equals HIDDEN. Otherwise hidden members are not returned. This is only supported by moderators.
]: any -> record<ChannelArn: record, Member: record<Arn: record, Name: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/memberships") $auth.query)
  let req_body = {"MemberArn": $member_arn, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists all channel memberships in a channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/memberships
# operationId: ListChannelMemberships
export def "channels-memberships list" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # The membership type of a user, DEFAULT or HIDDEN. Default members are always returned as part of ListChannelMemberships. Hidden members are only returned if the type filter in ListChannelMemberships equals HIDDEN. Otherwise hidden members are not returned.
  --max-results: int # The maximum number of channel memberships that you want returned.
  --next-token: string # The token passed by previous API calls until all requested channel memberships are returned. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelArn: record, ChannelMemberships: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/memberships") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new ChannelModerator. A channel moderator can: Add and remove other members of the channel. Add and remove other moderators of the channel. Add and remove user bans for the channel. Redact messages in the channel. List messages in the channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels/{channelArn}/moderators
# operationId: CreateChannelModerator
export def "channels-moderators create" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  channel_moderator_arn: string # The ARN of the moderator.
]: any -> record<ChannelArn: record, ChannelModerator: record<Arn: record, Name: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/moderators") $auth.query)
  let req_body = {"ChannelModeratorArn": $channel_moderator_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists all the moderators for a channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/moderators
# operationId: ListChannelModerators
export def "channels-moderators list" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of moderators that you want returned.
  --next-token: string # The token passed by previous API calls until all requested moderators are returned. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelArn: record, NextToken: record, ChannelModerators: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let qp = [(serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/moderators") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a media capture pipeline.
#
# POST /media-capture-pipelines
# operationId: CreateMediaCapturePipeline
# --ChimeSdkMeetingConfiguration shape: {SourceConfiguration?: any, ArtifactsConfiguration?: any}
export def "media-capture-pipelines create" [
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
  source_type: string@source-type-completer # Source type from which the media artifacts will be captured. A Chime SDK Meeting is the only supported source.
  source_arn: string # ARN of the source from which the media artifacts are captured. (format: password)
  sink_type: string@sink-type-completer # Destination type to which the media artifacts are saved. You must use an S3 bucket.
  sink_arn: string # The ARN of the sink type. (format: password)
  --client-request-token: string # The unique identifier for the client request. The token makes the API request idempotent. Use a different token for different media pipeline requests. (format: password)
  --chime-sdk-meeting-configuration: record # The configuration object of the Amazon Chime SDK meeting for a specified media capture pipeline. SourceType must be ChimeSdkMeeting. — shape: {SourceConfiguration?: any, ArtifactsConfiguration?: any}
]: any -> record<MediaCapturePipeline: record<MediaPipelineId: record, SourceType: record, SourceArn: record, Status: record, SinkType: record, SinkArn: record, CreatedTimestamp: record, UpdatedTimestamp: record, ChimeSdkMeetingConfiguration: record<SourceConfiguration: record, ArtifactsConfiguration: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/media-capture-pipelines" $auth.query)
  let req_body = {"SourceType": $source_type, "SourceArn": $source_arn, "SinkType": $sink_type, "SinkArn": $sink_arn, "ClientRequestToken": $client_request_token, "ChimeSdkMeetingConfiguration": $chime_sdk_meeting_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns a list of media capture pipelines.
#
# GET /media-capture-pipelines
# operationId: ListMediaCapturePipelines
export def "media-capture-pipelines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token used to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call. Valid Range: 1 - 99.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<MediaCapturePipelines: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/media-capture-pipelines" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next-token": $next_token, "max-results": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about specifying media Regions, see Amazon Chime SDK Media Regions (https://docs.aws.amazon.com/chime-sdk/latest/dg/chime-sdk-meetings-regions.html) in the Amazon Chime SDK Developer Guide . For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide .
#
# POST /meetings
# operationId: CreateMeeting
# --Tags item shape: {Key: any, Value: any}
# --NotificationsConfiguration shape: {SnsTopicArn?: any, SqsQueueArn?: any}
export def "meetings create" [
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
  client_request_token: string # The unique identifier for the client request. Use a different token for different meetings. (format: password)
  --external-meeting-id: string # The external meeting ID. (format: password)
  --meeting-host-id: string # Reserved. (format: password)
  --media-region: string # The Region in which to create the meeting. Default: us-east-1. Available values: af-south-1 , ap-northeast-1 , ap-northeast-2 , ap-south-1 , ap-southeast-1 , ap-southeast-2 , ca-central-1 , eu-central-1 , eu-north-1 , eu-south-1 , eu-west-1 , eu-west-2 , eu-west-3 , sa-east-1 , us-east-1 , us-east-2 , us-west-1 , us-west-2 .
  --tags: list # The tag key-value pairs. — item shape: {Key: any, Value: any}
  --notifications-configuration: record # The resource target configurations for receiving Amazon Chime SDK meeting and attendee event notifications. The Amazon Chime SDK supports resource targets located in the US East (N. Virginia) AWS Region (us-east-1). — shape: {SnsTopicArn?: any, SqsQueueArn?: any}
]: any -> record<Meeting: record<MeetingId: record, ExternalMeetingId: record, MediaPlacement: record<AudioHostUrl: record, AudioFallbackUrl: record, ScreenDataUrl: record, ScreenSharingUrl: record, ScreenViewingUrl: record, SignalingUrl: record, TurnControlUrl: record, EventIngestionUrl: record>, MediaRegion: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meetings" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "ExternalMeetingId": $external_meeting_id, "MeetingHostId": $meeting_host_id, "MediaRegion": $media_region, "Tags": $tags, "NotificationsConfiguration": $notifications_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# GET /meetings
# operationId: ListMeetings
export def "meetings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Meetings: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/meetings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next-token": $next_token, "max-results": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Uses the join token and call metadata in a meeting request (From number, To number, and so forth) to initiate an outbound call to a public switched telephone network (PSTN) and join them into a Chime meeting. Also ensures that the From number belongs to the customer. To play welcome audio or implement an interactive voice response (IVR), use the CreateSipMediaApplicationCall action with the corresponding SIP media application ID.
#
# POST /meetings/{meetingId}/dial-outs
# operationId: CreateMeetingDialOut
export def "meetings-dial-outs create" [
  meeting_id: string
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
  from_phone_number: string # Phone number used as the caller ID when the remote party receives a call. (format: password)
  to_phone_number: string # Phone number called when inviting someone to a meeting. (format: password)
  join_token: string # Token used by the Amazon Chime SDK attendee. Call the CreateAttendee (https://docs.aws.amazon.com/chime/latest/APIReference/API_CreateAttendee.html) action to get a join token. (format: password)
]: any -> record<TransactionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/dial-outs") $auth.query)
  let req_body = {"FromPhoneNumber": $from_phone_number, "ToPhoneNumber": $to_phone_number, "JoinToken": $join_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates a new Amazon Chime SDK meeting in the specified media Region, with attendees. For more information about specifying media Regions, see Amazon Chime SDK Media Regions (https://docs.aws.amazon.com/chime-sdk/latest/dg/chime-sdk-meetings-regions.html) in the Amazon Chime SDK Developer Guide . For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide .
#
# POST /meetings
# operationId: CreateMeetingWithAttendees
# --Tags item shape: {Key: any, Value: any}
# --NotificationsConfiguration shape: {SnsTopicArn?: any, SqsQueueArn?: any}
# --Attendees item shape: {ExternalUserId: any, Tags?: any}
export def "meetings create-with-attendees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-8
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  client_request_token: string # The unique identifier for the client request. Use a different token for different meetings. (format: password)
  --external-meeting-id: string # The external meeting ID. (format: password)
  --meeting-host-id: string # Reserved. (format: password)
  --media-region: string # The Region in which to create the meeting. Default: us-east-1 . Available values: af-south-1 , ap-northeast-1 , ap-northeast-2 , ap-south-1 , ap-southeast-1 , ap-southeast-2 , ca-central-1 , eu-central-1 , eu-north-1 , eu-south-1 , eu-west-1 , eu-west-2 , eu-west-3 , sa-east-1 , us-east-1 , us-east-2 , us-west-1 , us-west-2 .
  --tags: list # The tag key-value pairs. — item shape: {Key: any, Value: any}
  --notifications-configuration: record # The resource target configurations for receiving Amazon Chime SDK meeting and attendee event notifications. The Amazon Chime SDK supports resource targets located in the US East (N. Virginia) AWS Region (us-east-1). — shape: {SnsTopicArn?: any, SqsQueueArn?: any}
  --attendees: list # The request containing the attendees to create. — item shape: {ExternalUserId: any, Tags?: any}
]: any -> record<Meeting: record<MeetingId: record, ExternalMeetingId: record, MediaPlacement: record<AudioHostUrl: record, AudioFallbackUrl: record, ScreenDataUrl: record, ScreenSharingUrl: record, ScreenViewingUrl: record, SignalingUrl: record, TurnControlUrl: record, EventIngestionUrl: record>, MediaRegion: record>, Attendees: record, Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/meetings" $qp $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "ExternalMeetingId": $external_meeting_id, "MeetingHostId": $meeting_host_id, "MediaRegion": $media_region, "Tags": $tags, "NotificationsConfiguration": $notifications_configuration, "Attendees": $attendees} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Creates an order for phone numbers to be provisioned. For toll-free numbers, you cannot use the Amazon Chime Business Calling product type. For numbers outside the U.S., you must use the Amazon Chime SIP Media Application Dial-In product type.
#
# POST /phone-number-orders
# operationId: CreatePhoneNumberOrder
export def "phone-number-orders create" [
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
  product_type: string@product-type-completer # The phone number product type.
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
]: any -> record<PhoneNumberOrder: record<PhoneNumberOrderId: record, ProductType: record, Status: record, OrderedPhoneNumbers: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone-number-orders" $auth.query)
  let req_body = {"ProductType": $product_type, "E164PhoneNumbers": $e164_phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the phone number orders for the administrator's Amazon Chime account.
#
# GET /phone-number-orders
# operationId: ListPhoneNumberOrders
export def "phone-number-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<PhoneNumberOrders: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone-number-orders" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next-token": $next_token, "max-results": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a proxy session on the specified Amazon Chime Voice Connector for the specified participant phone numbers.
#
# POST /voice-connectors/{voiceConnectorId}/proxy-sessions
# operationId: CreateProxySession
# --GeoMatchParams shape: {Country?: any, AreaCode?: any}
export def "voice-connectors-proxy-sessions create" [
  voice_connector_id: string
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
  participant_phone_numbers: list<string> # The participant phone numbers.
  --name: string # The name of the proxy session. (format: password)
  --expiry-minutes: int # The number of minutes allowed for the proxy session.
  capabilities: list<string> # The proxy session capabilities.
  --number-selection-behavior: string@number-selection-behavior-completer # The preference for proxy phone number reuse, or stickiness, between the same participants across sessions.
  --geo-match-level: string@geo-match-level-completer # The preference for matching the country or area code of the proxy phone number with that of the first participant.
  --geo-match-params: record # The country and area code for a proxy phone number in a proxy phone session. — shape: {Country?: any, AreaCode?: any}
]: any -> record<ProxySession: record<VoiceConnectorId: record, ProxySessionId: record, Name: record, Status: record, ExpiryMinutes: record, Capabilities: record, CreatedTimestamp: record, UpdatedTimestamp: record, EndedTimestamp: record, Participants: record, NumberSelectionBehavior: record, GeoMatchLevel: record, GeoMatchParams: record<Country: record, AreaCode: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/proxy-sessions") $auth.query)
  let req_body = {"ParticipantPhoneNumbers": $participant_phone_numbers, "Name": $name, "ExpiryMinutes": $expiry_minutes, "Capabilities": $capabilities, "NumberSelectionBehavior": $number_selection_behavior, "GeoMatchLevel": $geo_match_level, "GeoMatchParams": $geo_match_params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the proxy sessions for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/proxy-sessions
# operationId: ListProxySessions
export def "voice-connectors-proxy-sessions list" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The proxy session status.
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ProxySessions: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/proxy-sessions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "next-token": $next_token, "max-results": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a chat room for the specified Amazon Chime Enterprise account.
#
# POST /accounts/{accountId}/rooms
# operationId: CreateRoom
export def "accounts-rooms create" [
  account_id: string
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
  name: string # The room name. (format: password)
  --client-request-token: string # The idempotency token for the request. (format: password)
]: any -> record<Room: record<RoomId: record, Name: record, AccountId: record, CreatedBy: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/rooms") $auth.query)
  let req_body = {"Name": $name, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the room details for the specified Amazon Chime Enterprise account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
#
# GET /accounts/{accountId}/rooms
# operationId: ListRooms
export def "accounts-rooms list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --member-id: string # The member ID (user ID or bot ID).
  --max-results: int # The maximum number of results to return in a single call.
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Rooms: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "member-id" $member_id "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/rooms") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"member-id": $member_id, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a member to a chat room in an Amazon Chime Enterprise account. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
#
# POST /accounts/{accountId}/rooms/{roomId}/memberships
# operationId: CreateRoomMembership
export def "accounts-rooms-memberships create" [
  account_id: string
  room_id: string
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
  member_id: string # The Amazon Chime member ID (user ID or bot ID).
  --role: string@role-completer # The role of the member.
]: any -> record<RoomMembership: record<RoomId: record, Member: record<MemberId: record, MemberType: record, Email: record, FullName: record, AccountId: record>, Role: record, InvitedBy: record, UpdatedTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), room_id: (encode-path-segment $room_id)} | format pattern "/accounts/{account_id}/rooms/{room_id}/memberships") $auth.query)
  let req_body = {"MemberId": $member_id, "Role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the membership details for the specified room in an Amazon Chime Enterprise account, such as the members' IDs, email addresses, and names.
#
# GET /accounts/{accountId}/rooms/{roomId}/memberships
# operationId: ListRoomMemberships
export def "accounts-rooms-memberships list" [
  account_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in a single call.
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RoomMemberships: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let qp = [(serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), room_id: (encode-path-segment $room_id)} | format pattern "/accounts/{account_id}/rooms/{room_id}/memberships") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a SIP media application.
#
# POST /sip-media-applications
# operationId: CreateSipMediaApplication
# --Endpoints item shape: {LambdaArn?: any}
export def "sip-media-applications create" [
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
  aws_region: string # The AWS Region assigned to the SIP media application.
  name: string # The SIP media application name.
  endpoints: list # List of endpoints (Lambda Amazon Resource Names) specified for the SIP media application. Currently, only one endpoint is supported. — item shape: {LambdaArn?: any}
]: any -> record<SipMediaApplication: record<SipMediaApplicationId: record, AwsRegion: record, Name: record, Endpoints: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sip-media-applications" $auth.query)
  let req_body = {"AwsRegion": $aws_region, "Name": $name, "Endpoints": $endpoints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the SIP media applications under the administrator's AWS account.
#
# GET /sip-media-applications
# operationId: ListSipMediaApplications
export def "sip-media-applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in a single call. Defaults to 100.
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SipMediaApplications: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sip-media-applications" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates an outbound call to a phone number from the phone number specified in the request, and it invokes the endpoint of the specified sipMediaApplicationId.
#
# POST /sip-media-applications/{sipMediaApplicationId}/calls
# operationId: CreateSipMediaApplicationCall
export def "sip-media-applications-calls create" [
  sip_media_application_id: string
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
  from_phone_number: string # The phone number that a user calls from. This is a phone number in your Amazon Chime phone number inventory. (format: password)
  to_phone_number: string # The phone number that the service should call. (format: password)
  --sip-headers: record # The SIP headers added to an outbound call leg.
]: any -> record<SipMediaApplicationCall: record<TransactionId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_media_application_id | is-empty) { error make --unspanned { msg: "path parameter 'sipMediaApplicationId' must be non-empty" } }
  let full_url = (build-url $base ({sip_media_application_id: (encode-path-segment $sip_media_application_id)} | format pattern "/sip-media-applications/{sip_media_application_id}/calls") $auth.query)
  let req_body = {"FromPhoneNumber": $from_phone_number, "ToPhoneNumber": $to_phone_number, "SipHeaders": $sip_headers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates a SIP rule which can be used to run a SIP media application as a target for a specific trigger type.
#
# POST /sip-rules
# operationId: CreateSipRule
# --TargetApplications item shape: {SipMediaApplicationId?: any, Priority?: any, AwsRegion?: any}
export def "sip-rules create" [
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
  name: string # The name of the SIP rule.
  trigger_type: string@trigger-type-completer # The type of trigger assigned to the SIP rule in TriggerValue, currently RequestUriHostname or ToPhoneNumber.
  trigger_value: string # If TriggerType is RequestUriHostname, the value can be the outbound host name of an Amazon Chime Voice Connector. If TriggerType is ToPhoneNumber, the value can be a customer-owned phone number in the E164 format. The SipMediaApplication specified in the SipRule is triggered if the request URI in an incoming SIP request matches the RequestUriHostname, or if the To header in the incoming SIP request matches the ToPhoneNumber value.
  --disabled: oneof<nothing, bool> # Enables or disables a rule. You must disable rules before you can delete them.
  target_applications: list # List of SIP media applications with priority and AWS Region. Only one SIP application per AWS Region can be used. — item shape: {SipMediaApplicationId?: any, Priority?: any, AwsRegion?: any}
]: any -> record<SipRule: record<SipRuleId: record, Name: record, Disabled: record, TriggerType: record, TriggerValue: record, TargetApplications: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sip-rules" $auth.query)
  let req_body = {"Name": $name, "TriggerType": $trigger_type, "TriggerValue": $trigger_value, "Disabled": $disabled, "TargetApplications": $target_applications} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the SIP rules under the administrator's AWS account.
#
# GET /sip-rules
# operationId: ListSipRules
export def "sip-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sip-media-application: string # The SIP media application ID.
  --max-results: int # The maximum number of results to return in a single call. Defaults to 100.
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SipRules: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sip-media-application" $sip_media_application "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sip-rules" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sip-media-application": $sip_media_application, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a user under the specified Amazon Chime account.
#
# POST /accounts/{accountId}/users
# operationId: CreateUser
export def "accounts-users create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-9
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --username: string # The user name.
  --email: string # The user's email address. (format: password)
  --user-type: string@user-type-completer # The user type.
]: any -> record<User: record<UserId: record, AccountId: record, PrimaryEmail: record, PrimaryProvisionedNumber: record, DisplayName: record, LicenseType: record, UserType: record, UserRegistrationStatus: record, UserInvitationStatus: record, RegisteredOn: record, InvitedOn: record, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: record, AlexaForBusinessRoomArn: record>, PersonalPIN: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/users") $qp $auth.query)
  let req_body = {"Username": $username, "Email": $email, "UserType": $user_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region. Enabling CreateVoiceConnectorRequest$RequireEncryption configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
#
# POST /voice-connectors
# operationId: CreateVoiceConnector
export def "voice-connectors create" [
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
  name: string # The name of the Amazon Chime Voice Connector.
  --aws-region: string@aws-region-completer # The AWS Region in which the Amazon Chime Voice Connector is created. Default value: us-east-1 .
  --require-encryption: oneof<nothing, bool> # When enabled, requires encryption for the Amazon Chime Voice Connector.
]: any -> record<VoiceConnector: record<VoiceConnectorId: record, AwsRegion: record, Name: record, OutboundHostName: record, RequireEncryption: record, CreatedTimestamp: record, UpdatedTimestamp: record, VoiceConnectorArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/voice-connectors" $auth.query)
  let req_body = {"Name": $name, "AwsRegion": $aws_region, "RequireEncryption": $require_encryption} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
#
# GET /voice-connectors
# operationId: ListVoiceConnectors
export def "voice-connectors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<VoiceConnectors: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/voice-connectors" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next-token": $next_token, "max-results": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including VoiceConnectorItems in the request. You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.
#
# POST /voice-connector-groups
# operationId: CreateVoiceConnectorGroup
# --VoiceConnectorItems item shape: {VoiceConnectorId: any, Priority: any}
export def "voice-connector-groups create" [
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
  name: string # The name of the Amazon Chime Voice Connector group.
  --voice-connector-items: list # The Amazon Chime Voice Connectors to route inbound calls to. — item shape: {VoiceConnectorId: any, Priority: any}
]: any -> record<VoiceConnectorGroup: record<VoiceConnectorGroupId: record, Name: record, VoiceConnectorItems: record, CreatedTimestamp: record, UpdatedTimestamp: record, VoiceConnectorGroupArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/voice-connector-groups" $auth.query)
  let req_body = {"Name": $name, "VoiceConnectorItems": $voice_connector_items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
#
# GET /voice-connector-groups
# operationId: ListVoiceConnectorGroups
export def "voice-connector-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results: int # The maximum number of results to return in a single call.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<VoiceConnectorGroups: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/voice-connector-groups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"next-token": $next_token, "max-results": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes the specified Amazon Chime account. You must suspend all users before deleting Team account. You can use the BatchSuspendUser action to dodo. For EnterpriseLWA and EnterpriseAD accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended. Deleted accounts appear in your Disabled accounts list for 90 days. To restore deleted account from your Disabled accounts list, you must contact AWS Support. After 90 days, deleted accounts are permanently removed from your Disabled accounts list.
#
# DELETE /accounts/{accountId}
# operationId: DeleteAccount
export def "accounts delete" [
  account_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
#
# GET /accounts/{accountId}
# operationId: GetAccount
export def "accounts get" [
  account_id: string
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
]: nothing -> record<Account: record<AwsAccountId: record, AccountId: record, Name: record, AccountType: record, CreatedTimestamp: record, DefaultLicense: record, SupportedLicenses: record, AccountStatus: record, SigninDelegateGroups: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates account details for the specified Amazon Chime account. Currently, only account name and default license updates are supported for this action.
#
# POST /accounts/{accountId}
# operationId: UpdateAccount
export def "accounts update" [
  account_id: string
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
  --name: string # The new name for the specified Amazon Chime account.
  --default-license: string@default-license-completer # The default license applied when you add users to an Amazon Chime account.
]: any -> record<Account: record<AwsAccountId: record, AccountId: record, Name: record, AccountType: record, CreatedTimestamp: record, DefaultLicense: record, SupportedLicenses: record, AccountStatus: record, SigninDelegateGroups: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $auth.query)
  let req_body = {"Name": $name, "DefaultLicense": $default_license} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes an AppInstance and all associated data asynchronously.
#
# DELETE /app-instances/{appInstanceArn}
# operationId: DeleteAppInstance
export def "app-instances delete" [
  app_instance_arn: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns the full details of an AppInstance.
#
# GET /app-instances/{appInstanceArn}
# operationId: DescribeAppInstance
export def "app-instances get" [
  app_instance_arn: string
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
]: nothing -> record<AppInstance: record<AppInstanceArn: record, Name: record, Metadata: record, CreatedTimestamp: record, LastUpdatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates AppInstance metadata.
#
# PUT /app-instances/{appInstanceArn}
# operationId: UpdateAppInstance
export def "app-instances update" [
  app_instance_arn: string
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
  name: string # The name that you want to change. (format: password)
  --metadata: string # The metadata that you want to change. (format: password)
]: any -> record<AppInstanceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}") $auth.query)
  let req_body = {"Name": $name, "Metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Demotes an AppInstanceAdmin to an AppInstanceUser. This action does not delete the user.
#
# DELETE /app-instances/{appInstanceArn}/admins/{appInstanceAdminArn}
# operationId: DeleteAppInstanceAdmin
export def "app-instances-admins delete" [
  app_instance_arn: string
  app_instance_admin_arn: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  if ($app_instance_admin_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceAdminArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn), app_instance_admin_arn: (encode-path-segment $app_instance_admin_arn)} | format pattern "/app-instances/{app_instance_arn}/admins/{app_instance_admin_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns the full details of an AppInstanceAdmin.
#
# GET /app-instances/{appInstanceArn}/admins/{appInstanceAdminArn}
# operationId: DescribeAppInstanceAdmin
export def "app-instances-admins get" [
  app_instance_arn: string
  app_instance_admin_arn: string
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
]: nothing -> record<AppInstanceAdmin: record<Admin: record<Arn: record, Name: record>, AppInstanceArn: record, CreatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  if ($app_instance_admin_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceAdminArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn), app_instance_admin_arn: (encode-path-segment $app_instance_admin_arn)} | format pattern "/app-instances/{app_instance_arn}/admins/{app_instance_admin_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes the streaming configurations of an AppInstance.
#
# DELETE /app-instances/{appInstanceArn}/streaming-configurations
# operationId: DeleteAppInstanceStreamingConfigurations
export def "app-instances-streaming-configurations delete" [
  app_instance_arn: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}/streaming-configurations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets the streaming settings for an AppInstance.
#
# GET /app-instances/{appInstanceArn}/streaming-configurations
# operationId: GetAppInstanceStreamingConfigurations
export def "app-instances-streaming-configurations get" [
  app_instance_arn: string
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
]: nothing -> record<AppInstanceStreamingConfigurations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}/streaming-configurations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# The data streaming configurations of an AppInstance.
#
# PUT /app-instances/{appInstanceArn}/streaming-configurations
# operationId: PutAppInstanceStreamingConfigurations
# --AppInstanceStreamingConfigurations item shape: {AppInstanceDataType: any, ResourceArn: any}
export def "app-instances-streaming-configurations update" [
  app_instance_arn: string
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
  app_instance_streaming_configurations: list # The streaming configurations set for an AppInstance. — item shape: {AppInstanceDataType: any, ResourceArn: any}
]: any -> record<AppInstanceStreamingConfigurations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}/streaming-configurations") $auth.query)
  let req_body = {"AppInstanceStreamingConfigurations": $app_instance_streaming_configurations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an AppInstanceUser.
#
# DELETE /app-instance-users/{appInstanceUserArn}
# operationId: DeleteAppInstanceUser
export def "app-instance-users delete" [
  app_instance_user_arn: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_user_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceUserArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_user_arn: (encode-path-segment $app_instance_user_arn)} | format pattern "/app-instance-users/{app_instance_user_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns the full details of an AppInstanceUser.
#
# GET /app-instance-users/{appInstanceUserArn}
# operationId: DescribeAppInstanceUser
export def "app-instance-users get" [
  app_instance_user_arn: string
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
]: nothing -> record<AppInstanceUser: record<AppInstanceUserArn: record, Name: record, CreatedTimestamp: record, Metadata: record, LastUpdatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_user_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceUserArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_user_arn: (encode-path-segment $app_instance_user_arn)} | format pattern "/app-instance-users/{app_instance_user_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the details of an AppInstanceUser. You can update names and metadata.
#
# PUT /app-instance-users/{appInstanceUserArn}
# operationId: UpdateAppInstanceUser
export def "app-instance-users update" [
  app_instance_user_arn: string
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
  name: string # The name of the AppInstanceUser. (format: password)
  --metadata: string # The metadata of the AppInstanceUser. (format: password)
]: any -> record<AppInstanceUserArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_user_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceUserArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_user_arn: (encode-path-segment $app_instance_user_arn)} | format pattern "/app-instance-users/{app_instance_user_arn}") $auth.query)
  let req_body = {"Name": $name, "Metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their JoinToken. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# DELETE /meetings/{meetingId}/attendees/{attendeeId}
# operationId: DeleteAttendee
export def "meetings-attendees delete" [
  meeting_id: string
  attendee_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($attendee_id | is-empty) { error make --unspanned { msg: "path parameter 'attendeeId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), attendee_id: (encode-path-segment $attendee_id)} | format pattern "/meetings/{meeting_id}/attendees/{attendee_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide .
#
# GET /meetings/{meetingId}/attendees/{attendeeId}
# operationId: GetAttendee
export def "meetings-attendees get" [
  meeting_id: string
  attendee_id: string
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
]: nothing -> record<Attendee: record<ExternalUserId: record, AttendeeId: record, JoinToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($attendee_id | is-empty) { error make --unspanned { msg: "path parameter 'attendeeId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), attendee_id: (encode-path-segment $attendee_id)} | format pattern "/meetings/{meeting_id}/attendees/{attendee_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Immediately makes a channel and its memberships inaccessible and marks them for deletion. This is an irreversible process. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}
# operationId: DeleteChannel
export def "channels delete" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns the full details of a channel in an Amazon Chime AppInstance. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}
# operationId: DescribeChannel
export def "channels get" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<Channel: record<Name: record, ChannelArn: record, Mode: record, Privacy: record, Metadata: record, CreatedBy: record<Arn: record, Name: record>, CreatedTimestamp: record, LastMessageTimestamp: record, LastUpdatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a channel's attributes. Restriction: You can't change a channel's privacy. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# PUT /channels/{channelArn}
# operationId: UpdateChannel
export def "channels update" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  name: string # The name of the channel. (format: password)
  mode: string@mode-completer # The mode of the update request.
  --metadata: string # The metadata for the update request. (format: password)
]: any -> record<ChannelArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}") $auth.query)
  let req_body = {"Name": $name, "Mode": $mode, "Metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes a user from a channel's ban list. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}/bans/{memberArn}
# operationId: DeleteChannelBan
export def "channels-bans delete" [
  channel_arn: string
  member_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($member_arn | is-empty) { error make --unspanned { msg: "path parameter 'memberArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), member_arn: (encode-path-segment $member_arn)} | format pattern "/channels/{channel_arn}/bans/{member_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns the full details of a channel ban. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/bans/{memberArn}
# operationId: DescribeChannelBan
export def "channels-bans get" [
  channel_arn: string
  member_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelBan: record<Member: record<Arn: record, Name: record>, ChannelArn: record, CreatedTimestamp: record, CreatedBy: record<Arn: record, Name: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($member_arn | is-empty) { error make --unspanned { msg: "path parameter 'memberArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), member_arn: (encode-path-segment $member_arn)} | format pattern "/channels/{channel_arn}/bans/{member_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Removes a member from a channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}/memberships/{memberArn}
# operationId: DeleteChannelMembership
export def "channels-memberships delete" [
  channel_arn: string
  member_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($member_arn | is-empty) { error make --unspanned { msg: "path parameter 'memberArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), member_arn: (encode-path-segment $member_arn)} | format pattern "/channels/{channel_arn}/memberships/{member_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns the full details of a user's channel membership. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/memberships/{memberArn}
# operationId: DescribeChannelMembership
export def "channels-memberships get" [
  channel_arn: string
  member_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelMembership: record<InvitedBy: record<Arn: record, Name: record>, Type: record, Member: record<Arn: record, Name: record>, ChannelArn: record, CreatedTimestamp: record, LastUpdatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($member_arn | is-empty) { error make --unspanned { msg: "path parameter 'memberArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), member_arn: (encode-path-segment $member_arn)} | format pattern "/channels/{channel_arn}/memberships/{member_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes a channel message. Only admins can perform this action. Deletion makes messages inaccessible immediately. A background process deletes any revisions created by UpdateChannelMessage. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}/messages/{messageId}
# operationId: DeleteChannelMessage
export def "channels-messages delete" [
  channel_arn: string
  message_id: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), message_id: (encode-path-segment $message_id)} | format pattern "/channels/{channel_arn}/messages/{message_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets the full details of a channel message. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/messages/{messageId}
# operationId: GetChannelMessage
export def "channels-messages get" [
  channel_arn: string
  message_id: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelMessage: record<ChannelArn: record, MessageId: record, Content: record, Metadata: record, Type: record, CreatedTimestamp: record, LastEditedTimestamp: record, LastUpdatedTimestamp: record, Sender: record<Arn: record, Name: record>, Redacted: record, Persistence: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), message_id: (encode-path-segment $message_id)} | format pattern "/channels/{channel_arn}/messages/{message_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the content of a message. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# PUT /channels/{channelArn}/messages/{messageId}
# operationId: UpdateChannelMessage
export def "channels-messages update" [
  channel_arn: string
  message_id: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  --content: string # The content of the message being updated. (format: password)
  --metadata: string # The metadata of the message being updated. (format: password)
]: any -> record<ChannelArn: record, MessageId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), message_id: (encode-path-segment $message_id)} | format pattern "/channels/{channel_arn}/messages/{message_id}") $auth.query)
  let req_body = {"Content": $content, "Metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a channel moderator. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# DELETE /channels/{channelArn}/moderators/{channelModeratorArn}
# operationId: DeleteChannelModerator
export def "channels-moderators delete" [
  channel_arn: string
  channel_moderator_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($channel_moderator_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelModeratorArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), channel_moderator_arn: (encode-path-segment $channel_moderator_arn)} | format pattern "/channels/{channel_arn}/moderators/{channel_moderator_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns the full details of a single ChannelModerator. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/moderators/{channelModeratorArn}
# operationId: DescribeChannelModerator
export def "channels-moderators get" [
  channel_arn: string
  channel_moderator_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelModerator: record<Moderator: record<Arn: record, Name: record>, ChannelArn: record, CreatedTimestamp: record, CreatedBy: record<Arn: record, Name: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($channel_moderator_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelModeratorArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), channel_moderator_arn: (encode-path-segment $channel_moderator_arn)} | format pattern "/channels/{channel_arn}/moderators/{channel_moderator_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes the events configuration that allows a bot to receive outgoing events.
#
# DELETE /accounts/{accountId}/bots/{botId}/events-configuration
# operationId: DeleteEventsConfiguration
export def "accounts-bots-events-configuration delete" [
  account_id: string
  bot_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), bot_id: (encode-path-segment $bot_id)} | format pattern "/accounts/{account_id}/bots/{bot_id}/events-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN.
#
# GET /accounts/{accountId}/bots/{botId}/events-configuration
# operationId: GetEventsConfiguration
export def "accounts-bots-events-configuration get" [
  account_id: string
  bot_id: string
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
]: nothing -> record<EventsConfiguration: record<BotId: record, OutboundEventsHTTPSEndpoint: record, LambdaFunctionArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), bot_id: (encode-path-segment $bot_id)} | format pattern "/accounts/{account_id}/bots/{bot_id}/events-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see Bot.
#
# PUT /accounts/{accountId}/bots/{botId}/events-configuration
# operationId: PutEventsConfiguration
export def "accounts-bots-events-configuration update" [
  account_id: string
  bot_id: string
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
  --outbound-events-https-endpoint: string # HTTPS endpoint that allows the bot to receive outgoing events. (format: password)
  --lambda-function-arn: string # Lambda function ARN that allows the bot to receive outgoing events. (format: password)
]: any -> record<EventsConfiguration: record<BotId: record, OutboundEventsHTTPSEndpoint: record, LambdaFunctionArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), bot_id: (encode-path-segment $bot_id)} | format pattern "/accounts/{account_id}/bots/{bot_id}/events-configuration") $auth.query)
  let req_body = {"OutboundEventsHTTPSEndpoint": $outbound_events_https_endpoint, "LambdaFunctionArn": $lambda_function_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Deletes the media capture pipeline.
#
# DELETE /media-capture-pipelines/{mediaPipelineId}
# operationId: DeleteMediaCapturePipeline
export def "media-capture-pipelines delete" [
  media_pipeline_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_pipeline_id | is-empty) { error make --unspanned { msg: "path parameter 'mediaPipelineId' must be non-empty" } }
  let full_url = (build-url $base ({media_pipeline_id: (encode-path-segment $media_pipeline_id)} | format pattern "/media-capture-pipelines/{media_pipeline_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets an existing media capture pipeline.
#
# GET /media-capture-pipelines/{mediaPipelineId}
# operationId: GetMediaCapturePipeline
export def "media-capture-pipelines get" [
  media_pipeline_id: string
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
]: nothing -> record<MediaCapturePipeline: record<MediaPipelineId: record, SourceType: record, SourceArn: record, Status: record, SinkType: record, SinkArn: record, CreatedTimestamp: record, UpdatedTimestamp: record, ChimeSdkMeetingConfiguration: record<SourceConfiguration: record, ArtifactsConfiguration: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_pipeline_id | is-empty) { error make --unspanned { msg: "path parameter 'mediaPipelineId' must be non-empty" } }
  let full_url = (build-url $base ({media_pipeline_id: (encode-path-segment $media_pipeline_id)} | format pattern "/media-capture-pipelines/{media_pipeline_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes the specified Amazon Chime SDK meeting. The operation deletes all attendees, disconnects all clients, and prevents new clients from joining the meeting. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide.
#
# DELETE /meetings/{meetingId}
# operationId: DeleteMeeting
export def "meetings delete" [
  meeting_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see Using the Amazon Chime SDK (https://docs.aws.amazon.com/chime-sdk/latest/dg/meetings-sdk.html) in the Amazon Chime SDK Developer Guide .
#
# GET /meetings/{meetingId}
# operationId: GetMeeting
export def "meetings get" [
  meeting_id: string
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
]: nothing -> record<Meeting: record<MeetingId: record, ExternalMeetingId: record, MediaPlacement: record<AudioHostUrl: record, AudioFallbackUrl: record, ScreenDataUrl: record, ScreenSharingUrl: record, ScreenViewingUrl: record, SignalingUrl: record, TurnControlUrl: record, EventIngestionUrl: record>, MediaRegion: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Moves the specified phone number into the Deletion queue. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted. Deleted phone numbers remain in the Deletion queue for 7 days before they are deleted permanently.
#
# DELETE /phone-numbers/{phoneNumberId}
# operationId: DeletePhoneNumber
export def "phone-numbers delete" [
  phone_number_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone-numbers/{phone_number_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
#
# GET /phone-numbers/{phoneNumberId}
# operationId: GetPhoneNumber
export def "phone-numbers get" [
  phone_number_id: string
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
]: nothing -> record<PhoneNumber: record<PhoneNumberId: record, E164PhoneNumber: record, Country: record, Type: record, ProductType: record, Status: record, Capabilities: record<InboundCall: record, OutboundCall: record, InboundSMS: record, OutboundSMS: record, InboundMMS: record, OutboundMMS: record>, Associations: record, CallingName: record, CallingNameStatus: record, CreatedTimestamp: record, UpdatedTimestamp: record, DeletionTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone-numbers/{phone_number_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action. For toll-free numbers, you cannot use the Amazon Chime Business Calling product type. For numbers outside the U.S., you must use the Amazon Chime SIP Media Application Dial-In product type. Updates to outbound calling names can take 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.
#
# POST /phone-numbers/{phoneNumberId}
# operationId: UpdatePhoneNumber
export def "phone-numbers update" [
  phone_number_id: string
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
  --product-type: string@product-type-completer # The product type.
  --calling-name: string # The outbound calling name associated with the phone number. (format: password)
]: any -> record<PhoneNumber: record<PhoneNumberId: record, E164PhoneNumber: record, Country: record, Type: record, ProductType: record, Status: record, Capabilities: record<InboundCall: record, OutboundCall: record, InboundSMS: record, OutboundSMS: record, InboundMMS: record, OutboundMMS: record>, Associations: record, CallingName: record, CallingNameStatus: record, CreatedTimestamp: record, UpdatedTimestamp: record, DeletionTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone-numbers/{phone_number_id}") $auth.query)
  let req_body = {"ProductType": $product_type, "CallingName": $calling_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes the specified proxy session from the specified Amazon Chime Voice Connector.
#
# DELETE /voice-connectors/{voiceConnectorId}/proxy-sessions/{proxySessionId}
# operationId: DeleteProxySession
export def "voice-connectors-proxy-sessions delete" [
  voice_connector_id: string
  proxy_session_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  if ($proxy_session_id | is-empty) { error make --unspanned { msg: "path parameter 'proxySessionId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id), proxy_session_id: (encode-path-segment $proxy_session_id)} | format pattern "/voice-connectors/{voice_connector_id}/proxy-sessions/{proxy_session_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets the specified proxy session details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/proxy-sessions/{proxySessionId}
# operationId: GetProxySession
export def "voice-connectors-proxy-sessions get" [
  voice_connector_id: string
  proxy_session_id: string
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
]: nothing -> record<ProxySession: record<VoiceConnectorId: record, ProxySessionId: record, Name: record, Status: record, ExpiryMinutes: record, Capabilities: record, CreatedTimestamp: record, UpdatedTimestamp: record, EndedTimestamp: record, Participants: record, NumberSelectionBehavior: record, GeoMatchLevel: record, GeoMatchParams: record<Country: record, AreaCode: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  if ($proxy_session_id | is-empty) { error make --unspanned { msg: "path parameter 'proxySessionId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id), proxy_session_id: (encode-path-segment $proxy_session_id)} | format pattern "/voice-connectors/{voice_connector_id}/proxy-sessions/{proxy_session_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the specified proxy session details, such as voice or SMS capabilities.
#
# POST /voice-connectors/{voiceConnectorId}/proxy-sessions/{proxySessionId}
# operationId: UpdateProxySession
export def "voice-connectors-proxy-sessions update" [
  voice_connector_id: string
  proxy_session_id: string
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
  capabilities: list<string> # The proxy session capabilities.
  --expiry-minutes: int # The number of minutes allowed for the proxy session.
]: any -> record<ProxySession: record<VoiceConnectorId: record, ProxySessionId: record, Name: record, Status: record, ExpiryMinutes: record, Capabilities: record, CreatedTimestamp: record, UpdatedTimestamp: record, EndedTimestamp: record, Participants: record, NumberSelectionBehavior: record, GeoMatchLevel: record, GeoMatchParams: record<Country: record, AreaCode: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  if ($proxy_session_id | is-empty) { error make --unspanned { msg: "path parameter 'proxySessionId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id), proxy_session_id: (encode-path-segment $proxy_session_id)} | format pattern "/voice-connectors/{voice_connector_id}/proxy-sessions/{proxy_session_id}") $auth.query)
  let req_body = {"Capabilities": $capabilities, "ExpiryMinutes": $expiry_minutes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes a chat room in an Amazon Chime Enterprise account.
#
# DELETE /accounts/{accountId}/rooms/{roomId}
# operationId: DeleteRoom
export def "accounts-rooms delete" [
  account_id: string
  room_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), room_id: (encode-path-segment $room_id)} | format pattern "/accounts/{account_id}/rooms/{room_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves room details, such as the room name, for a room in an Amazon Chime Enterprise account.
#
# GET /accounts/{accountId}/rooms/{roomId}
# operationId: GetRoom
export def "accounts-rooms get" [
  account_id: string
  room_id: string
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
]: nothing -> record<Room: record<RoomId: record, Name: record, AccountId: record, CreatedBy: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), room_id: (encode-path-segment $room_id)} | format pattern "/accounts/{account_id}/rooms/{room_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates room details, such as the room name, for a room in an Amazon Chime Enterprise account.
#
# POST /accounts/{accountId}/rooms/{roomId}
# operationId: UpdateRoom
export def "accounts-rooms update" [
  account_id: string
  room_id: string
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
  --name: string # The room name. (format: password)
]: any -> record<Room: record<RoomId: record, Name: record, AccountId: record, CreatedBy: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), room_id: (encode-path-segment $room_id)} | format pattern "/accounts/{account_id}/rooms/{room_id}") $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Removes a member from a chat room in an Amazon Chime Enterprise account.
#
# DELETE /accounts/{accountId}/rooms/{roomId}/memberships/{memberId}
# operationId: DeleteRoomMembership
export def "accounts-rooms-memberships delete" [
  account_id: string
  room_id: string
  member_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), room_id: (encode-path-segment $room_id), member_id: (encode-path-segment $member_id)} | format pattern "/accounts/{account_id}/rooms/{room_id}/memberships/{member_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates room membership details, such as the member role, for a room in an Amazon Chime Enterprise account. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
#
# POST /accounts/{accountId}/rooms/{roomId}/memberships/{memberId}
# operationId: UpdateRoomMembership
export def "accounts-rooms-memberships update" [
  account_id: string
  room_id: string
  member_id: string
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
  --role: string@role-completer # The role of the member.
]: any -> record<RoomMembership: record<RoomId: record, Member: record<MemberId: record, MemberType: record, Email: record, FullName: record, AccountId: record>, Role: record, InvitedBy: record, UpdatedTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), room_id: (encode-path-segment $room_id), member_id: (encode-path-segment $member_id)} | format pattern "/accounts/{account_id}/rooms/{room_id}/memberships/{member_id}") $auth.query)
  let req_body = {"Role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes a SIP media application.
#
# DELETE /sip-media-applications/{sipMediaApplicationId}
# operationId: DeleteSipMediaApplication
export def "sip-media-applications delete" [
  sip_media_application_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_media_application_id | is-empty) { error make --unspanned { msg: "path parameter 'sipMediaApplicationId' must be non-empty" } }
  let full_url = (build-url $base ({sip_media_application_id: (encode-path-segment $sip_media_application_id)} | format pattern "/sip-media-applications/{sip_media_application_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves the information for a SIP media application, including name, AWS Region, and endpoints.
#
# GET /sip-media-applications/{sipMediaApplicationId}
# operationId: GetSipMediaApplication
export def "sip-media-applications get" [
  sip_media_application_id: string
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
]: nothing -> record<SipMediaApplication: record<SipMediaApplicationId: record, AwsRegion: record, Name: record, Endpoints: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_media_application_id | is-empty) { error make --unspanned { msg: "path parameter 'sipMediaApplicationId' must be non-empty" } }
  let full_url = (build-url $base ({sip_media_application_id: (encode-path-segment $sip_media_application_id)} | format pattern "/sip-media-applications/{sip_media_application_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the details of the specified SIP media application.
#
# PUT /sip-media-applications/{sipMediaApplicationId}
# operationId: UpdateSipMediaApplication
# --Endpoints item shape: {LambdaArn?: any}
export def "sip-media-applications update" [
  sip_media_application_id: string
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
  --name: string # The new name for the specified SIP media application.
  --endpoints: list # The new set of endpoints for the specified SIP media application. — item shape: {LambdaArn?: any}
]: any -> record<SipMediaApplication: record<SipMediaApplicationId: record, AwsRegion: record, Name: record, Endpoints: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_media_application_id | is-empty) { error make --unspanned { msg: "path parameter 'sipMediaApplicationId' must be non-empty" } }
  let full_url = (build-url $base ({sip_media_application_id: (encode-path-segment $sip_media_application_id)} | format pattern "/sip-media-applications/{sip_media_application_id}") $auth.query)
  let req_body = {"Name": $name, "Endpoints": $endpoints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a SIP rule. You must disable a SIP rule before you can delete it.
#
# DELETE /sip-rules/{sipRuleId}
# operationId: DeleteSipRule
export def "sip-rules delete" [
  sip_rule_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_rule_id | is-empty) { error make --unspanned { msg: "path parameter 'sipRuleId' must be non-empty" } }
  let full_url = (build-url $base ({sip_rule_id: (encode-path-segment $sip_rule_id)} | format pattern "/sip-rules/{sip_rule_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves the details of a SIP rule, such as the rule ID, name, triggers, and target endpoints.
#
# GET /sip-rules/{sipRuleId}
# operationId: GetSipRule
export def "sip-rules get" [
  sip_rule_id: string
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
]: nothing -> record<SipRule: record<SipRuleId: record, Name: record, Disabled: record, TriggerType: record, TriggerValue: record, TargetApplications: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_rule_id | is-empty) { error make --unspanned { msg: "path parameter 'sipRuleId' must be non-empty" } }
  let full_url = (build-url $base ({sip_rule_id: (encode-path-segment $sip_rule_id)} | format pattern "/sip-rules/{sip_rule_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the details of the specified SIP rule.
#
# PUT /sip-rules/{sipRuleId}
# operationId: UpdateSipRule
# --TargetApplications item shape: {SipMediaApplicationId?: any, Priority?: any, AwsRegion?: any}
export def "sip-rules update" [
  sip_rule_id: string
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
  name: string # The new name for the specified SIP rule.
  --disabled: oneof<nothing, bool> # The new value specified to indicate whether the rule is disabled.
  --target-applications: list # The new value of the list of target applications. — item shape: {SipMediaApplicationId?: any, Priority?: any, AwsRegion?: any}
]: any -> record<SipRule: record<SipRuleId: record, Name: record, Disabled: record, TriggerType: record, TriggerValue: record, TargetApplications: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_rule_id | is-empty) { error make --unspanned { msg: "path parameter 'sipRuleId' must be non-empty" } }
  let full_url = (build-url $base ({sip_rule_id: (encode-path-segment $sip_rule_id)} | format pattern "/sip-rules/{sip_rule_id}") $auth.query)
  let req_body = {"Name": $name, "Disabled": $disabled, "TargetApplications": $target_applications} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
#
# DELETE /voice-connectors/{voiceConnectorId}
# operationId: DeleteVoiceConnector
export def "voice-connectors delete" [
  voice_connector_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps,name, outbound host, and encryption requirements.
#
# GET /voice-connectors/{voiceConnectorId}
# operationId: GetVoiceConnector
export def "voice-connectors get" [
  voice_connector_id: string
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
]: nothing -> record<VoiceConnector: record<VoiceConnectorId: record, AwsRegion: record, Name: record, OutboundHostName: record, RequireEncryption: record, CreatedTimestamp: record, UpdatedTimestamp: record, VoiceConnectorArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates details for the specified Amazon Chime Voice Connector.
#
# PUT /voice-connectors/{voiceConnectorId}
# operationId: UpdateVoiceConnector
export def "voice-connectors update" [
  voice_connector_id: string
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
  name: string # The name of the Amazon Chime Voice Connector.
  --require-encryption: oneof<nothing, bool> # When enabled, requires encryption for the Amazon Chime Voice Connector.
]: any -> record<VoiceConnector: record<VoiceConnectorId: record, AwsRegion: record, Name: record, OutboundHostName: record, RequireEncryption: record, CreatedTimestamp: record, UpdatedTimestamp: record, VoiceConnectorArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}") $auth.query)
  let req_body = {"Name": $name, "RequireEncryption": $require_encryption} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the emergency calling configuration details from the specified Amazon Chime Voice Connector.
#
# DELETE /voice-connectors/{voiceConnectorId}/emergency-calling-configuration
# operationId: DeleteVoiceConnectorEmergencyCallingConfiguration
export def "voice-connectors-emergency-calling-configuration delete" [
  voice_connector_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/emergency-calling-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets the emergency calling configuration details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/emergency-calling-configuration
# operationId: GetVoiceConnectorEmergencyCallingConfiguration
export def "voice-connectors-emergency-calling-configuration get" [
  voice_connector_id: string
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
]: nothing -> record<EmergencyCallingConfiguration: record<DNIS: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/emergency-calling-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Puts emergency calling configuration details to the specified Amazon Chime Voice Connector, such as emergency phone numbers and calling countries. Origination and termination settings must be enabled for the Amazon Chime Voice Connector before emergency calling can be configured.
#
# PUT /voice-connectors/{voiceConnectorId}/emergency-calling-configuration
# operationId: PutVoiceConnectorEmergencyCallingConfiguration
# --EmergencyCallingConfiguration shape: {DNIS?: any}
export def "voice-connectors-emergency-calling-configuration update" [
  voice_connector_id: string
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
  emergency_calling_configuration: record # The emergency calling configuration details associated with an Amazon Chime Voice Connector. — shape: {DNIS?: any}
]: any -> record<EmergencyCallingConfiguration: record<DNIS: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/emergency-calling-configuration") $auth.query)
  let req_body = {"EmergencyCallingConfiguration": $emergency_calling_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the specified Amazon Chime Voice Connector group. Any VoiceConnectorItems and phone numbers associated with the group must be removed before it can be deleted.
#
# DELETE /voice-connector-groups/{voiceConnectorGroupId}
# operationId: DeleteVoiceConnectorGroup
export def "voice-connector-groups delete" [
  voice_connector_group_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_group_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorGroupId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_group_id: (encode-path-segment $voice_connector_group_id)} | format pattern "/voice-connector-groups/{voice_connector_group_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps,name, and associated VoiceConnectorItems.
#
# GET /voice-connector-groups/{voiceConnectorGroupId}
# operationId: GetVoiceConnectorGroup
export def "voice-connector-groups get" [
  voice_connector_group_id: string
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
]: nothing -> record<VoiceConnectorGroup: record<VoiceConnectorGroupId: record, Name: record, VoiceConnectorItems: record, CreatedTimestamp: record, UpdatedTimestamp: record, VoiceConnectorGroupArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_group_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorGroupId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_group_id: (encode-path-segment $voice_connector_group_id)} | format pattern "/voice-connector-groups/{voice_connector_group_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates details of the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
#
# PUT /voice-connector-groups/{voiceConnectorGroupId}
# operationId: UpdateVoiceConnectorGroup
# --VoiceConnectorItems item shape: {VoiceConnectorId: any, Priority: any}
export def "voice-connector-groups update" [
  voice_connector_group_id: string
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
  name: string # The name of the Amazon Chime Voice Connector group.
  voice_connector_items: list # The VoiceConnectorItems to associate with the group. — item shape: {VoiceConnectorId: any, Priority: any}
]: any -> record<VoiceConnectorGroup: record<VoiceConnectorGroupId: record, Name: record, VoiceConnectorItems: record, CreatedTimestamp: record, UpdatedTimestamp: record, VoiceConnectorGroupArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_group_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorGroupId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_group_id: (encode-path-segment $voice_connector_group_id)} | format pattern "/voice-connector-groups/{voice_connector_group_id}") $auth.query)
  let req_body = {"Name": $name, "VoiceConnectorItems": $voice_connector_items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Deletes the origination settings for the specified Amazon Chime Voice Connector. If emergency calling is configured for the Amazon Chime Voice Connector, it must be deleted prior to deleting the origination settings.
#
# DELETE /voice-connectors/{voiceConnectorId}/origination
# operationId: DeleteVoiceConnectorOrigination
export def "voice-connectors-origination delete" [
  voice_connector_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/origination") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves origination setting details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/origination
# operationId: GetVoiceConnectorOrigination
export def "voice-connectors-origination get" [
  voice_connector_id: string
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
]: nothing -> record<Origination: record<Routes: record, Disabled: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/origination") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Adds origination settings for the specified Amazon Chime Voice Connector. If emergency calling is configured for the Amazon Chime Voice Connector, it must be deleted prior to turning off origination settings.
#
# PUT /voice-connectors/{voiceConnectorId}/origination
# operationId: PutVoiceConnectorOrigination
# --Origination shape: {Routes?: any, Disabled?: any}
export def "voice-connectors-origination update" [
  voice_connector_id: string
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
  origination: record # Origination settings enable your SIP hosts to receive inbound calls using your Amazon Chime Voice Connector. The parameters listed below are not required, but you must use at least one. — shape: {Routes?: any, Disabled?: any}
]: any -> record<Origination: record<Routes: record, Disabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/origination") $auth.query)
  let req_body = {"Origination": $origination} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the proxy configuration from the specified Amazon Chime Voice Connector.
#
# DELETE /voice-connectors/{voiceConnectorId}/programmable-numbers/proxy
# operationId: DeleteVoiceConnectorProxy
export def "voice-connectors-programmable-numbers-proxy delete" [
  voice_connector_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/programmable-numbers/proxy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets the proxy configuration details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/programmable-numbers/proxy
# operationId: GetVoiceConnectorProxy
export def "voice-connectors-programmable-numbers-proxy get" [
  voice_connector_id: string
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
]: nothing -> record<Proxy: record<DefaultSessionExpiryMinutes: record, Disabled: record, FallBackPhoneNumber: record, PhoneNumberCountries: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/programmable-numbers/proxy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Puts the specified proxy configuration to the specified Amazon Chime Voice Connector.
#
# PUT /voice-connectors/{voiceConnectorId}/programmable-numbers/proxy
# operationId: PutVoiceConnectorProxy
export def "voice-connectors-programmable-numbers-proxy update" [
  voice_connector_id: string
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
  default_session_expiry_minutes: int # The default number of minutes allowed for proxy sessions.
  phone_number_pool_countries: list<string> # The countries for proxy phone numbers to be selected from.
  --fall-back-phone-number: string # The phone number to route calls to after a proxy session expires. (format: password)
  --disabled: oneof<nothing, bool> # When true, stops proxy sessions from being created on the specified Amazon Chime Voice Connector.
]: any -> record<Proxy: record<DefaultSessionExpiryMinutes: record, Disabled: record, FallBackPhoneNumber: record, PhoneNumberCountries: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/programmable-numbers/proxy") $auth.query)
  let req_body = {"DefaultSessionExpiryMinutes": $default_session_expiry_minutes, "PhoneNumberPoolCountries": $phone_number_pool_countries, "FallBackPhoneNumber": $fall_back_phone_number, "Disabled": $disabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
#
# DELETE /voice-connectors/{voiceConnectorId}/streaming-configuration
# operationId: DeleteVoiceConnectorStreamingConfiguration
export def "voice-connectors-streaming-configuration delete" [
  voice_connector_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/streaming-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
#
# GET /voice-connectors/{voiceConnectorId}/streaming-configuration
# operationId: GetVoiceConnectorStreamingConfiguration
export def "voice-connectors-streaming-configuration get" [
  voice_connector_id: string
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
]: nothing -> record<StreamingConfiguration: record<DataRetentionInHours: record, Disabled: record, StreamingNotificationTargets: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/streaming-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
#
# PUT /voice-connectors/{voiceConnectorId}/streaming-configuration
# operationId: PutVoiceConnectorStreamingConfiguration
# --StreamingConfiguration shape: {DataRetentionInHours?: any, Disabled?: any, StreamingNotificationTargets?: any}
export def "voice-connectors-streaming-configuration update" [
  voice_connector_id: string
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
  streaming_configuration: record # The streaming configuration associated with an Amazon Chime Voice Connector. Specifies whether media streaming is enabled for sending to Amazon Kinesis, and shows the retention period for the Amazon Kinesis data, in hours. — shape: {DataRetentionInHours?: any, Disabled?: any, StreamingNotificationTargets?: any}
]: any -> record<StreamingConfiguration: record<DataRetentionInHours: record, Disabled: record, StreamingNotificationTargets: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/streaming-configuration") $auth.query)
  let req_body = {"StreamingConfiguration": $streaming_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the termination settings for the specified Amazon Chime Voice Connector. If emergency calling is configured for the Amazon Chime Voice Connector, it must be deleted prior to deleting the termination settings.
#
# DELETE /voice-connectors/{voiceConnectorId}/termination
# operationId: DeleteVoiceConnectorTermination
export def "voice-connectors-termination delete" [
  voice_connector_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/termination") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves termination setting details for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/termination
# operationId: GetVoiceConnectorTermination
export def "voice-connectors-termination get" [
  voice_connector_id: string
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
]: nothing -> record<Termination: record<CpsLimit: record, DefaultPhoneNumber: record, CallingRegions: record, CidrAllowedList: record, Disabled: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/termination") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Adds termination settings for the specified Amazon Chime Voice Connector. If emergency calling is configured for the Amazon Chime Voice Connector, it must be deleted prior to turning off termination settings.
#
# PUT /voice-connectors/{voiceConnectorId}/termination
# operationId: PutVoiceConnectorTermination
# --Termination shape: {CpsLimit?: any, DefaultPhoneNumber?: any, CallingRegions?: any, CidrAllowedList?: any, Disabled?: any}
export def "voice-connectors-termination update" [
  voice_connector_id: string
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
  termination: record # Termination settings enable your SIP hosts to make outbound calls using your Amazon Chime Voice Connector. — shape: {CpsLimit?: any, DefaultPhoneNumber?: any, CallingRegions?: any, CidrAllowedList?: any, Disabled?: any}
]: any -> record<Termination: record<CpsLimit: record, DefaultPhoneNumber: record, CallingRegions: record, CidrAllowedList: record, Disabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/termination") $auth.query)
  let req_body = {"Termination": $termination} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
#
# POST /voice-connectors/{voiceConnectorId}/termination/credentials
# operationId: DeleteVoiceConnectorTerminationCredentials
export def "voice-connectors-termination-credentials delete" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-10
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  usernames: list<string> # The RFC2617 compliant username associated with the SIP credentials, in US-ASCII format.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/termination/credentials") $qp $auth.query)
  let req_body = {"Usernames": $usernames} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns the details of a channel based on the membership of the specified AppInstanceUser. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}
# operationId: DescribeChannelMembershipForAppInstanceUser
export def "channels get-membership-for-app-instance-user" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-user-arn: string # The ARN of the user in a channel.
  --scope: string@scope-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelMembership: record<ChannelSummary: record<Name: record, ChannelArn: record, Mode: record, Privacy: record, Metadata: record, LastMessageTimestamp: record>, AppInstanceUserMembershipSummary: record<Type: record, ReadMarkerTimestamp: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let qp = [(serialize-qp "app-instance-user-arn" $app_instance_user_arn "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"app-instance-user-arn": $app_instance_user_arn, "scope": $scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the full details of a channel moderated by the specified AppInstanceUser. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}
# operationId: DescribeChannelModeratedByAppInstanceUser
export def "channels get-moderated-by-app-instance-user" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-user-arn: string # The ARN of the AppInstanceUser in the moderated channel.
  --scope: string@scope-completer-1
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<Channel: record<ChannelSummary: record<Name: record, ChannelArn: record, Mode: record, Privacy: record, Metadata: record, LastMessageTimestamp: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let qp = [(serialize-qp "app-instance-user-arn" $app_instance_user_arn "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"app-instance-user-arn": $app_instance_user_arn, "scope": $scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Disassociates the primary provisioned phone number from the specified Amazon Chime user.
#
# POST /accounts/{accountId}/users/{userId}
# operationId: DisassociatePhoneNumberFromUser
export def "accounts-users create-disassociate-phone-number" [
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-11
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), user_id: (encode-path-segment $user_id)} | format pattern "/accounts/{account_id}/users/{user_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
#
# POST /voice-connectors/{voiceConnectorId}
# operationId: DisassociatePhoneNumbersFromVoiceConnector
export def "voice-connectors create-disassociate-phone-numbers" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-12
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
]: any -> record<PhoneNumberErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}") $qp $auth.query)
  let req_body = {"E164PhoneNumbers": $e164_phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
#
# POST /voice-connector-groups/{voiceConnectorGroupId}
# operationId: DisassociatePhoneNumbersFromVoiceConnectorGroup
export def "voice-connector-groups create-disassociate-phone-numbers" [
  voice_connector_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-12
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  e164_phone_numbers: list<string> # List of phone numbers, in E.164 format.
]: any -> record<PhoneNumberErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_group_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorGroupId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({voice_connector_group_id: (encode-path-segment $voice_connector_group_id)} | format pattern "/voice-connector-groups/{voice_connector_group_id}") $qp $auth.query)
  let req_body = {"E164PhoneNumbers": $e164_phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
#
# POST /accounts/{accountId}
# operationId: DisassociateSigninDelegateGroupsFromAccount
export def "accounts create-disassociate-signin-delegate-groups" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-13
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  group_names: list<string> # The sign-in delegate group names.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $qp $auth.query)
  let req_body = {"GroupNames": $group_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dialout settings. For more information about these settings, see Use the Policies Page (https://docs.aws.amazon.com/chime/latest/ag/policies.html) in the Amazon Chime Administration Guide.
#
# GET /accounts/{accountId}/settings
# operationId: GetAccountSettings
export def "accounts-settings get" [
  account_id: string
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
]: nothing -> record<AccountSettings: record<DisableRemoteControl: record, EnableDialOut: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/settings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see Use the Policies Page (https://docs.aws.amazon.com/chime/latest/ag/policies.html) in the Amazon Chime Administration Guide.
#
# PUT /accounts/{accountId}/settings
# operationId: UpdateAccountSettings
# --AccountSettings shape: {DisableRemoteControl?: any, EnableDialOut?: any}
export def "accounts-settings update" [
  account_id: string
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
  account_settings: record # Settings related to the Amazon Chime account. This includes settings that start or stop remote control of shared screens, or start or stop the dial-out option in the Amazon Chime web application. For more information about these settings, see Use the Policies Page (https://docs.aws.amazon.com/chime/latest/ag/policies.html) in the Amazon Chime Administration Guide. — shape: {DisableRemoteControl?: any, EnableDialOut?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/settings") $auth.query)
  let req_body = {"AccountSettings": $account_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Gets the retention settings for an AppInstance.
#
# GET /app-instances/{appInstanceArn}/retention-settings
# operationId: GetAppInstanceRetentionSettings
export def "app-instances-retention-settings get" [
  app_instance_arn: string
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
]: nothing -> record<AppInstanceRetentionSettings: record<ChannelRetentionSettings: record<RetentionDays: record>>, InitiateDeletionTimestamp: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}/retention-settings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Sets the amount of time in days that a given AppInstance retains data.
#
# PUT /app-instances/{appInstanceArn}/retention-settings
# operationId: PutAppInstanceRetentionSettings
# --AppInstanceRetentionSettings shape: {ChannelRetentionSettings?: any}
export def "app-instances-retention-settings update" [
  app_instance_arn: string
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
  app_instance_retention_settings: record # The details of the data-retention settings for an AppInstance. — shape: {ChannelRetentionSettings?: any}
]: any -> record<AppInstanceRetentionSettings: record<ChannelRetentionSettings: record<RetentionDays: record>>, InitiateDeletionTimestamp: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'appInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({app_instance_arn: (encode-path-segment $app_instance_arn)} | format pattern "/app-instances/{app_instance_arn}/retention-settings") $auth.query)
  let req_body = {"AppInstanceRetentionSettings": $app_instance_retention_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
#
# GET /accounts/{accountId}/bots/{botId}
# operationId: GetBot
export def "accounts-bots get" [
  account_id: string
  bot_id: string
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
]: nothing -> record<Bot: record<BotId: record, UserId: record, DisplayName: record, BotType: record, Disabled: record, CreatedTimestamp: record, UpdatedTimestamp: record, BotEmail: record, SecurityToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), bot_id: (encode-path-segment $bot_id)} | format pattern "/accounts/{account_id}/bots/{bot_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
#
# POST /accounts/{accountId}/bots/{botId}
# operationId: UpdateBot
export def "accounts-bots update" [
  account_id: string
  bot_id: string
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
  --disabled: oneof<nothing, bool> # When true, stops the specified bot from running in your account.
]: any -> record<Bot: record<BotId: record, UserId: record, DisplayName: record, BotType: record, Disabled: record, CreatedTimestamp: record, UpdatedTimestamp: record, BotEmail: record, SecurityToken: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), bot_id: (encode-path-segment $bot_id)} | format pattern "/accounts/{account_id}/bots/{bot_id}") $auth.query)
  let req_body = {"Disabled": $disabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
#
# GET /settings
# operationId: GetGlobalSettings
export def "settings get-global" [
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
]: nothing -> record<BusinessCalling: record<CdrBucket: record>, VoiceConnector: record<CdrBucket: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
#
# PUT /settings
# operationId: UpdateGlobalSettings
# --BusinessCalling shape: {CdrBucket?: any}
# --VoiceConnector shape: {CdrBucket?: any}
export def "settings update-global" [
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
  --business-calling: record # The Amazon Chime Business Calling settings for the administrator's AWS account. Includes any Amazon S3 buckets designated for storing call detail records. — shape: {CdrBucket?: any}
  --voice-connector: record # The Amazon Chime Voice Connector settings. Includes any Amazon S3 buckets designated for storing call detail records. — shape: {CdrBucket?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings" $auth.query)
  let req_body = {"BusinessCalling": $business_calling, "VoiceConnector": $voice_connector} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# The details of the endpoint for the messaging session.
#
# GET /endpoints/messaging-session
# operationId: GetMessagingSessionEndpoint
export def "endpoints-messaging-session get" [
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
]: nothing -> record<Endpoint: record<Url: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoints/messaging-session" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves details for the specified phone number order, such as the order creation timestamp, phone numbers in E.164 format, product type, and order status.
#
# GET /phone-number-orders/{phoneNumberOrderId}
# operationId: GetPhoneNumberOrder
export def "phone-number-orders get" [
  phone_number_order_id: string
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
]: nothing -> record<PhoneNumberOrder: record<PhoneNumberOrderId: record, ProductType: record, Status: record, OrderedPhoneNumbers: record, CreatedTimestamp: record, UpdatedTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number_order_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumberOrderId' must be non-empty" } }
  let full_url = (build-url $base ({phone_number_order_id: (encode-path-segment $phone_number_order_id)} | format pattern "/phone-number-orders/{phone_number_order_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
#
# GET /settings/phone-number
# operationId: GetPhoneNumberSettings
export def "settings-phone-number get" [
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
]: nothing -> record<CallingName: record, CallingNameUpdatedTimestamp: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/phone-number" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
#
# PUT /settings/phone-number
# operationId: UpdatePhoneNumberSettings
export def "settings-phone-number update" [
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
  calling_name: string # The default outbound calling name for the account. (format: password)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/phone-number" $auth.query)
  let req_body = {"CallingName": $calling_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Gets the retention settings for the specified Amazon Chime Enterprise account. For more information about retention settings, see Managing Chat Retention Policies (https://docs.aws.amazon.com/chime/latest/ag/chat-retention.html) in the Amazon Chime Administration Guide.
#
# GET /accounts/{accountId}/retention-settings
# operationId: GetRetentionSettings
export def "accounts-retention-settings get" [
  account_id: string
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
]: nothing -> record<RetentionSettings: record<RoomRetentionSettings: record<RetentionDays: record>, ConversationRetentionSettings: record<RetentionDays: record>>, InitiateDeletionTimestamp: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/retention-settings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Puts retention settings for the specified Amazon Chime Enterprise account. We recommend using AWS CloudTrail to monitor usage of this API for your account. For more information, see Logging Amazon Chime API Calls with AWS CloudTrail (https://docs.aws.amazon.com/chime/latest/ag/cloudtrail.html) in the Amazon Chime Administration Guide. To turn off existing retention settings, remove the number of days from the corresponding RetentionDays field in the RetentionSettings object. For more information about retention settings, see Managing Chat Retention Policies (https://docs.aws.amazon.com/chime/latest/ag/chat-retention.html) in the Amazon Chime Administration Guide.
#
# PUT /accounts/{accountId}/retention-settings
# operationId: PutRetentionSettings
# --RetentionSettings shape: {RoomRetentionSettings?: any, ConversationRetentionSettings?: any}
export def "accounts-retention-settings update" [
  account_id: string
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
  retention_settings: record # The retention settings for an Amazon Chime Enterprise account that determine how long to retain items such as chat-room messages and chat-conversation messages. — shape: {RoomRetentionSettings?: any, ConversationRetentionSettings?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/retention-settings") $auth.query)
  let req_body = {"RetentionSettings": $retention_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns the logging configuration for the specified SIP media application.
#
# GET /sip-media-applications/{sipMediaApplicationId}/logging-configuration
# operationId: GetSipMediaApplicationLoggingConfiguration
export def "sip-media-applications-logging-configuration get" [
  sip_media_application_id: string
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
]: nothing -> record<SipMediaApplicationLoggingConfiguration: record<EnableSipMediaApplicationMessageLogs: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_media_application_id | is-empty) { error make --unspanned { msg: "path parameter 'sipMediaApplicationId' must be non-empty" } }
  let full_url = (build-url $base ({sip_media_application_id: (encode-path-segment $sip_media_application_id)} | format pattern "/sip-media-applications/{sip_media_application_id}/logging-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the logging configuration for the specified SIP media application.
#
# PUT /sip-media-applications/{sipMediaApplicationId}/logging-configuration
# operationId: PutSipMediaApplicationLoggingConfiguration
# --SipMediaApplicationLoggingConfiguration shape: {EnableSipMediaApplicationMessageLogs?: any}
export def "sip-media-applications-logging-configuration update" [
  sip_media_application_id: string
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
  --sip-media-application-logging-configuration: record # Logging configuration of the SIP media application. — shape: {EnableSipMediaApplicationMessageLogs?: any}
]: any -> record<SipMediaApplicationLoggingConfiguration: record<EnableSipMediaApplicationMessageLogs: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_media_application_id | is-empty) { error make --unspanned { msg: "path parameter 'sipMediaApplicationId' must be non-empty" } }
  let full_url = (build-url $base ({sip_media_application_id: (encode-path-segment $sip_media_application_id)} | format pattern "/sip-media-applications/{sip_media_application_id}/logging-configuration") $auth.query)
  let req_body = {"SipMediaApplicationLoggingConfiguration": $sip_media_application_logging_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves details for the specified user ID, such as primary email address, license type,and personal meeting PIN. To retrieve user details with an email address instead of a user ID, use the ListUsers action, and then filter by email address.
#
# GET /accounts/{accountId}/users/{userId}
# operationId: GetUser
export def "accounts-users get" [
  account_id: string
  user_id: string
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
]: nothing -> record<User: record<UserId: record, AccountId: record, PrimaryEmail: record, PrimaryProvisionedNumber: record, DisplayName: record, LicenseType: record, UserType: record, UserRegistrationStatus: record, UserInvitationStatus: record, RegisteredOn: record, InvitedOn: record, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: record, AlexaForBusinessRoomArn: record>, PersonalPIN: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), user_id: (encode-path-segment $user_id)} | format pattern "/accounts/{account_id}/users/{user_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates user details for a specified user ID. Currently, only LicenseType updates are supported for this action.
#
# POST /accounts/{accountId}/users/{userId}
# operationId: UpdateUser
# --AlexaForBusinessMetadata shape: {IsAlexaForBusinessEnabled?: any, AlexaForBusinessRoomArn?: any}
export def "accounts-users update" [
  account_id: string
  user_id: string
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
  --license-type: string@license-type-completer # The user license type to update. This must be a supported license type for the Amazon Chime account that the user belongs to.
  --user-type: string@user-type-completer # The user type.
  --alexa-for-business-metadata: record # The Alexa for Business metadata associated with an Amazon Chime user, used to integrate Alexa for Business with a device. — shape: {IsAlexaForBusinessEnabled?: any, AlexaForBusinessRoomArn?: any}
]: any -> record<User: record<UserId: record, AccountId: record, PrimaryEmail: record, PrimaryProvisionedNumber: record, DisplayName: record, LicenseType: record, UserType: record, UserRegistrationStatus: record, UserInvitationStatus: record, RegisteredOn: record, InvitedOn: record, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: record, AlexaForBusinessRoomArn: record>, PersonalPIN: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), user_id: (encode-path-segment $user_id)} | format pattern "/accounts/{account_id}/users/{user_id}") $auth.query)
  let req_body = {"LicenseType": $license_type, "UserType": $user_type, "AlexaForBusinessMetadata": $alexa_for_business_metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieves settings for the specified user ID, such as any associated phone number settings.
#
# GET /accounts/{accountId}/users/{userId}/settings
# operationId: GetUserSettings
export def "accounts-users-settings get" [
  account_id: string
  user_id: string
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
]: nothing -> record<UserSettings: record<Telephony: record<InboundCalling: record, OutboundCalling: record, SMS: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), user_id: (encode-path-segment $user_id)} | format pattern "/accounts/{account_id}/users/{user_id}/settings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates the settings for the specified user, such as phone number settings.
#
# PUT /accounts/{accountId}/users/{userId}/settings
# operationId: UpdateUserSettings
# --UserSettings shape: {Telephony?: any}
export def "accounts-users-settings update" [
  account_id: string
  user_id: string
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
  user_settings: record # Settings associated with an Amazon Chime user, including inbound and outbound calling and text messaging. — shape: {Telephony?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), user_id: (encode-path-segment $user_id)} | format pattern "/accounts/{account_id}/users/{user_id}/settings") $auth.query)
  let req_body = {"UserSettings": $user_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
#
# GET /voice-connectors/{voiceConnectorId}/logging-configuration
# operationId: GetVoiceConnectorLoggingConfiguration
export def "voice-connectors-logging-configuration get" [
  voice_connector_id: string
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
]: nothing -> record<LoggingConfiguration: record<EnableSIPLogs: record, EnableMediaMetricLogs: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/logging-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
#
# PUT /voice-connectors/{voiceConnectorId}/logging-configuration
# operationId: PutVoiceConnectorLoggingConfiguration
# --LoggingConfiguration shape: {EnableSIPLogs?: any, EnableMediaMetricLogs?: any}
export def "voice-connectors-logging-configuration update" [
  voice_connector_id: string
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
  logging_configuration: record # The logging configuration associated with an Amazon Chime Voice Connector. Specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs. — shape: {EnableSIPLogs?: any, EnableMediaMetricLogs?: any}
]: any -> record<LoggingConfiguration: record<EnableSIPLogs: record, EnableMediaMetricLogs: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/logging-configuration") $auth.query)
  let req_body = {"LoggingConfiguration": $logging_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves information about the last time a SIP OPTIONS ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/termination/health
# operationId: GetVoiceConnectorTerminationHealth
export def "voice-connectors-termination-health get" [
  voice_connector_id: string
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
]: nothing -> record<TerminationHealth: record<Timestamp: record, Source: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/termination/health") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime Team account. Only Team account types are currently supported for this action.
#
# POST /accounts/{accountId}/users
# operationId: InviteUsers
export def "accounts-users create-invite" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-14
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  user_email_list: list<string> # The user email addresses to which to send the email invitation.
  --user-type: string@user-type-completer # The user type.
]: any -> record<Invites: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/users") $qp $auth.query)
  let req_body = {"UserEmailList": $user_email_list, "UserType": $user_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List all AppInstanceUsers created under a single AppInstance.
#
# GET /app-instance-users
# operationId: ListAppInstanceUsers
export def "app-instance-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-arn: string # The ARN of the AppInstance.
  --max-results: int # The maximum number of requests that you want returned.
  --next-token: string # The token passed by previous API calls until all requested users are returned. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AppInstanceArn: record, AppInstanceUsers: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app-instance-arn" $app_instance_arn "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/app-instance-users" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"app-instance-arn": $app_instance_arn, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists the tags applied to an Amazon Chime SDK attendee resource.
#
# GET /meetings/{meetingId}/attendees/{attendeeId}/tags
# operationId: ListAttendeeTags
export def "meetings-attendees-tags list" [
  meeting_id: string
  attendee_id: string
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
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($attendee_id | is-empty) { error make --unspanned { msg: "path parameter 'attendeeId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), attendee_id: (encode-path-segment $attendee_id)} | format pattern "/meetings/{meeting_id}/attendees/{attendee_id}/tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists all channels that a particular AppInstanceUser is a part of. Only an AppInstanceAdmin can call the API with a user ARN that is not their own. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels
# operationId: ListChannelMembershipsForAppInstanceUser
export def "channels list-memberships-for-app-instance-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-user-arn: string # The ARN of the AppInstanceUsers
  --max-results: int # The maximum number of users that you want returned.
  --next-token: string # The token returned from previous API requests until the number of channel memberships is reached. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --scope: string@scope-completer-2
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelMemberships: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app-instance-user-arn" $app_instance_user_arn "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"app-instance-user-arn": $app_instance_user_arn, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2, "scope": $scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all the messages in a channel. Returns a paginated list of ChannelMessages. By default, sorted by creation timestamp in descending order. Redacted messages appear in the results as empty, since they are only redacted, not deleted. Deleted messages do not appear in the results. This action always returns the latest version of an edited message. Also, the x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels/{channelArn}/messages
# operationId: ListChannelMessages
export def "channels-messages list" [
  channel_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-order: string@sort-order-completer # The order in which you want messages sorted. Default is Descending, based on time created.
  --not-before: string # The initial or starting time stamp for your requested messages. (format: date-time)
  --not-after: string # The final or ending time stamp for your requested messages. (format: date-time)
  --max-results: int # The maximum number of messages that you want returned.
  --next-token: string # The token passed by previous API calls until all requested messages are returned. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelArn: record, NextToken: record, ChannelMessages: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let qp = [(serialize-qp "sort-order" $sort_order "scalar") (serialize-qp "not-before" $not_before "scalar") (serialize-qp "not-after" $not_after "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/messages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort-order": $sort_order, "not-before": $not_before, "not-after": $not_after, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Sends a message to a particular channel that the member is a part of. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header. Also, STANDARD messages can contain 4KB of data and the 1KB of metadata. CONTROL messages can contain 30 bytes of data and no metadata.
#
# POST /channels/{channelArn}/messages
# operationId: SendChannelMessage
export def "channels-messages send" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
  content: string # The content of the message. (format: password)
  type: string@type-completer-1 # The type of message, STANDARD or CONTROL.
  persistence: string@persistence-completer # Boolean that controls whether the message is persisted on the back end. Required.
  --metadata: string # The optional metadata for each message. (format: password)
  client_request_token: string # The Idempotency token for each client request. (format: password)
]: any -> record<ChannelArn: record, MessageId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/messages") $auth.query)
  let req_body = {"Content": $content, "Type": $type, "Persistence": $persistence, "Metadata": $metadata, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists all Channels created under a single Chime App as a paginated list. You can specify filters to narrow results. Functionality & restrictions Use privacy = PUBLIC to retrieve all public channels in the account. Only an AppInstanceAdmin can set privacy = PRIVATE to list the private channels in an account. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels
# operationId: ListChannels
export def "channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-arn: string # The ARN of the AppInstance.
  --privacy: string@privacy-completer # The privacy setting. PUBLIC retrieves all the public channels. PRIVATE retrieves private channels. Only an AppInstanceAdmin can retrieve private channels.
  --max-results: int # The maximum number of channels that you want to return.
  --next-token: string # The token passed by previous API calls until all requested channels are returned. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<Channels: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app-instance-arn" $app_instance_arn "scalar") (serialize-qp "privacy" $privacy "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"app-instance-arn": $app_instance_arn, "privacy": $privacy, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# A list of the channels moderated by an AppInstanceUser. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# GET /channels
# operationId: ListChannelsModeratedByAppInstanceUser
export def "channels list-moderated-by-app-instance-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-instance-user-arn: string # The ARN of the user in the moderated channel.
  --max-results: int # The maximum number of channels in the request.
  --next-token: string # The token returned from previous API requests until the number of channels moderated by the user is reached. (format: password)
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --scope: string@scope-completer-3
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<Channels: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app-instance-user-arn" $app_instance_user_arn "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"app-instance-user-arn": $app_instance_user_arn, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2, "scope": $scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists the tags applied to an Amazon Chime SDK meeting resource.
#
# GET /meetings/{meetingId}/tags
# operationId: ListMeetingTags
export def "meetings-tags list" [
  meeting_id: string
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
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
#
# GET /phone-numbers
# operationId: ListPhoneNumbers
export def "phone-numbers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # The phone number status.
  --product-type: string@product-type-completer # The phone number product type.
  --filter-name: string@filter-name-completer # The filter to use to limit the number of results.
  --filter-value: string # The value to use for the filter.
  --max-results: int # The maximum number of results to return in a single call.
  --next-token: string # The token to use to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<PhoneNumbers: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "product-type" $product_type "scalar") (serialize-qp "filter-name" $filter_name "scalar") (serialize-qp "filter-value" $filter_value "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone-numbers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "product-type": $product_type, "filter-name": $filter_name, "filter-value": $filter_value, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists supported phone number countries.
#
# GET /phone-number-countries
# operationId: ListSupportedPhoneNumberCountries
export def "phone-number-countries list-supported" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-type: string@product-type-completer # The phone number product type.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<PhoneNumberCountries: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product-type" $product_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone-number-countries" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"product-type": $product_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists the tags applied to an Amazon Chime SDK meeting resource.
#
# GET /tags
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --arn: string # The resource ARN. (format: password)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "arn" $arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"arn": $arn} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists the SIP credentials for the specified Amazon Chime Voice Connector.
#
# GET /voice-connectors/{voiceConnectorId}/termination/credentials
# operationId: ListVoiceConnectorTerminationCredentials
export def "voice-connectors-termination-credentials list" [
  voice_connector_id: string
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
]: nothing -> record<Usernames: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/termination/credentials") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Logs out the specified user from all of the devices they are currently logged into.
#
# POST /accounts/{accountId}/users/{userId}
# operationId: LogoutUser
export def "accounts-users create-logout" [
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-15
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), user_id: (encode-path-segment $user_id)} | format pattern "/accounts/{account_id}/users/{user_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
#
# POST /voice-connectors/{voiceConnectorId}/termination/credentials
# operationId: PutVoiceConnectorTerminationCredentials
# --Credentials item shape: {Username?: any, Password?: any}
export def "voice-connectors-termination-credentials update" [
  voice_connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-16
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --credentials: list # The termination SIP credentials. — item shape: {Username?: any, Password?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voice_connector_id | is-empty) { error make --unspanned { msg: "path parameter 'voiceConnectorId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({voice_connector_id: (encode-path-segment $voice_connector_id)} | format pattern "/voice-connectors/{voice_connector_id}/termination/credentials") $qp $auth.query)
  let req_body = {"Credentials": $credentials} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Redacts message content, but not metadata. The message exists in the back end, but the action returns null content, and the state shows as redacted. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# POST /channels/{channelArn}/messages/{messageId}
# operationId: RedactChannelMessage
export def "channels-messages create-redact" [
  channel_arn: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-17
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelArn: record, MessageId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn), message_id: (encode-path-segment $message_id)} | format pattern "/channels/{channel_arn}/messages/{message_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Redacts the specified message from the specified Amazon Chime conversation.
#
# POST /accounts/{accountId}/conversations/{conversationId}/messages/{messageId}
# operationId: RedactConversationMessage
export def "accounts-conversations-messages create-redact" [
  account_id: string
  conversation_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-17
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversationId' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), conversation_id: (encode-path-segment $conversation_id), message_id: (encode-path-segment $message_id)} | format pattern "/accounts/{account_id}/conversations/{conversation_id}/messages/{message_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Redacts the specified message from the specified Amazon Chime channel.
#
# POST /accounts/{accountId}/rooms/{roomId}/messages/{messageId}
# operationId: RedactRoomMessage
export def "accounts-rooms-messages create-redact" [
  account_id: string
  room_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-17
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'roomId' must be non-empty" } }
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), room_id: (encode-path-segment $room_id), message_id: (encode-path-segment $message_id)} | format pattern "/accounts/{account_id}/rooms/{room_id}/messages/{message_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Regenerates the security token for a bot.
#
# POST /accounts/{accountId}/bots/{botId}
# operationId: RegenerateSecurityToken
export def "accounts-bots create-regenerate-security-token" [
  account_id: string
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-18
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Bot: record<BotId: record, UserId: record, DisplayName: record, BotType: record, Disabled: record, CreatedTimestamp: record, UpdatedTimestamp: record, BotEmail: record, SecurityToken: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), bot_id: (encode-path-segment $bot_id)} | format pattern "/accounts/{account_id}/bots/{bot_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the User object with the updated personal meeting PIN.
#
# POST /accounts/{accountId}/users/{userId}
# operationId: ResetPersonalPIN
export def "accounts-users reset-personal-pin" [
  account_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-19
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<User: record<UserId: record, AccountId: record, PrimaryEmail: record, PrimaryProvisionedNumber: record, DisplayName: record, LicenseType: record, UserType: record, UserRegistrationStatus: record, UserInvitationStatus: record, RegisteredOn: record, InvitedOn: record, AlexaForBusinessMetadata: record<IsAlexaForBusinessEnabled: record, AlexaForBusinessRoomArn: record>, PersonalPIN: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), user_id: (encode-path-segment $user_id)} | format pattern "/accounts/{account_id}/users/{user_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Moves a phone number from the Deletion queue back into the phone number Inventory.
#
# POST /phone-numbers/{phoneNumberId}
# operationId: RestorePhoneNumber
export def "phone-numbers create-restore" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-20
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<PhoneNumber: record<PhoneNumberId: record, E164PhoneNumber: record, Country: record, Type: record, ProductType: record, Status: record, Capabilities: record<InboundCall: record, OutboundCall: record, InboundSMS: record, OutboundSMS: record, InboundMMS: record, OutboundMMS: record>, Associations: record, CallingName: record, CallingNameStatus: record, CreatedTimestamp: record, UpdatedTimestamp: record, DeletionTimestamp: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumberId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone-numbers/{phone_number_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Searches for phone numbers that can be ordered. For US numbers, provide at least one of the following search filters: AreaCode, City, State, or TollFreePrefix. If you provide City, you must also provide State. Numbers outside the US only support the PhoneNumberType filter, which you must use.
#
# GET /search
# operationId: SearchAvailablePhoneNumbers
export def "search list-available-phone-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: string # The area code used to filter results. Only applies to the US.
  --city: string # The city used to filter results. Only applies to the US.
  --country: string # The country used to filter results. Defaults to the US Format: ISO 3166-1 alpha-2.
  --state: string # The state used to filter results. Required only if you provide City. Only applies to the US.
  --toll-free-prefix: string # The toll-free prefix that you use to filter results. Only applies to the US.
  --phone-number-type: string@phone-number-type-completer # The phone number type used to filter results. Required for non-US numbers.
  --max-results: int # The maximum number of results to return in a single call.
  --next-token: string # The token used to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --type: string@type-completer-2
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<E164PhoneNumbers: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "area-code" $area_code "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "toll-free-prefix" $toll_free_prefix "scalar") (serialize-qp "phone-number-type" $phone_number_type "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "next-token" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"area-code": $area_code, "city": $city, "country": $country, "state": $state, "toll-free-prefix": $toll_free_prefix, "phone-number-type": $phone_number_type, "max-results": $max_results, "next-token": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Starts transcription for the specified meetingId. For more information, refer to Using Amazon Chime SDK live transcription (https://docs.aws.amazon.com/chime-sdk/latest/dg/meeting-transcription.html) in the Amazon Chime SDK Developer Guide. If you specify an invalid configuration, a TranscriptFailed event will be sent with the contents of the BadRequestException generated by Amazon Transcribe. For more information on each parameter and which combinations are valid, refer to the StartStreamTranscription (https://docs.aws.amazon.com/transcribe/latest/APIReference/API_streaming_StartStreamTranscription.html) API in the Amazon Transcribe Developer Guide. Amazon Chime SDK live transcription is powered by Amazon Transcribe. Use of Amazon Transcribe is subject to the AWS Service Terms (https://aws.amazon.com/service-terms/), including the terms specific to the AWS Machine Learning and Artificial Intelligence Services.
#
# POST /meetings/{meetingId}/transcription
# operationId: StartMeetingTranscription
# --TranscriptionConfiguration shape: {EngineTranscribeSettings?: any, EngineTranscribeMedicalSettings?: any}
export def "meetings-transcription start" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-21
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  transcription_configuration: record # The configuration for the current transcription operation. Must contain EngineTranscribeSettings or EngineTranscribeMedicalSettings. — shape: {EngineTranscribeSettings?: any, EngineTranscribeMedicalSettings?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/transcription") $qp $auth.query)
  let req_body = {"TranscriptionConfiguration": $transcription_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Stops transcription for the specified meetingId.
#
# POST /meetings/{meetingId}/transcription
# operationId: StopMeetingTranscription
export def "meetings-transcription stop" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-22
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/transcription") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Applies the specified tags to the specified Amazon Chime SDK attendee.
#
# POST /meetings/{meetingId}/attendees/{attendeeId}/tags
# operationId: TagAttendee
# --Tags item shape: {Key: any, Value: any}
export def "meetings-attendees-tags tag" [
  meeting_id: string
  attendee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-14
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: list # The tag key-value pairs. — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($attendee_id | is-empty) { error make --unspanned { msg: "path parameter 'attendeeId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), attendee_id: (encode-path-segment $attendee_id)} | format pattern "/meetings/{meeting_id}/attendees/{attendee_id}/tags") $qp $auth.query)
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Applies the specified tags to the specified Amazon Chime SDK meeting.
#
# POST /meetings/{meetingId}/tags
# operationId: TagMeeting
# --Tags item shape: {Key: any, Value: any}
export def "meetings-tags tag" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-14
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: list # The tag key-value pairs. — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/tags") $qp $auth.query)
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Applies the specified tags to the specified Amazon Chime SDK meeting resource.
#
# POST /tags
# operationId: TagResource
# --Tags item shape: {Key: any, Value: any}
export def "tags tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-23
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_arn: string # The resource ARN. (format: password)
  tags: list # The tag key-value pairs. — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Untags the specified tags from the specified Amazon Chime SDK attendee.
#
# POST /meetings/{meetingId}/attendees/{attendeeId}/tags
# operationId: UntagAttendee
export def "meetings-attendees-tags untag" [
  meeting_id: string
  attendee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-10
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tag_keys: list<string> # The tag keys.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  if ($attendee_id | is-empty) { error make --unspanned { msg: "path parameter 'attendeeId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id), attendee_id: (encode-path-segment $attendee_id)} | format pattern "/meetings/{meeting_id}/attendees/{attendee_id}/tags") $qp $auth.query)
  let req_body = {"TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Untags the specified tags from the specified Amazon Chime SDK meeting.
#
# POST /meetings/{meetingId}/tags
# operationId: UntagMeeting
export def "meetings-tags untag" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-10
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tag_keys: list<string> # The tag keys.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/tags") $qp $auth.query)
  let req_body = {"TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Untags the specified tags from the specified Amazon Chime SDK meeting resource.
#
# POST /tags
# operationId: UntagResource
export def "tags untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-24
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_arn: string # The resource ARN. (format: password)
  tag_keys: list<string> # The tag keys.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# The details of the time when a user last read messages in a channel. The x-amz-chime-bearer request header is mandatory. Use the AppInstanceUserArn of the user that makes the API call as the value in the header.
#
# PUT /channels/{channelArn}/readMarker
# operationId: UpdateChannelReadMarker
export def "channels-read-marker update" [
  channel_arn: string
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
  --x-amz-chime-bearer: string # The AppInstanceUserArn of the user that makes the API call.
]: nothing -> record<ChannelArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_arn | is-empty) { error make --unspanned { msg: "path parameter 'channelArn' must be non-empty" } }
  let full_url = (build-url $base ({channel_arn: (encode-path-segment $channel_arn)} | format pattern "/channels/{channel_arn}/readMarker") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-chime-bearer": $x_amz_chime_bearer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Invokes the AWS Lambda function associated with the SIP media application and transaction ID in an update request. The Lambda function can then return a new set of actions.
#
# POST /sip-media-applications/{sipMediaApplicationId}/calls/{transactionId}
# operationId: UpdateSipMediaApplicationCall
export def "sip-media-applications-calls update" [
  sip_media_application_id: string
  transaction_id: string
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
  arguments: record # Arguments made available to the Lambda function as part of the CALL_UPDATE_REQUESTED event. Can contain 0-20 key-value pairs.
]: any -> record<SipMediaApplicationCall: record<TransactionId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sip_media_application_id | is-empty) { error make --unspanned { msg: "path parameter 'sipMediaApplicationId' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({sip_media_application_id: (encode-path-segment $sip_media_application_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/sip-media-applications/{sip_media_application_id}/calls/{transaction_id}") $auth.query)
  let req_body = {"Arguments": $arguments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Validates an address to be used for 911 calls made with Amazon Chime Voice Connectors. You can use validated addresses in a Presence Information Data Format Location Object file that you include in SIP requests. That helps ensure that addresses are routed to the appropriate Public Safety Answering Point.
#
# POST /emergency-calling/address
# operationId: ValidateE911Address
export def "emergency-calling-address validate-e911" [
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
  aws_account_id: string # The AWS account ID.
  street_number: string # The address street number, such as 200 or 2121. (format: password)
  street_info: string # The address street information, such as 8th Avenue. (format: password)
  city: string # The address city, such as Portland. (format: password)
  state: string # The address state, such as ME. (format: password)
  country: string # The address country, such as US. (format: password)
  postal_code: string # The address postal code, such as 04352. (format: password)
]: any -> record<ValidationResult: record, AddressExternalId: record, Address: record<streetName: record, streetSuffix: record, postDirectional: record, preDirectional: record, streetNumber: record, city: record, state: record, postalCode: record, postalCodePlus4: record, country: record>, CandidateAddressList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emergency-calling/address" $auth.query)
  let req_body = {"AwsAccountId": $aws_account_id, "StreetNumber": $street_number, "StreetInfo": $street_info, "City": $city, "State": $state, "Country": $country, "PostalCode": $postal_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}
