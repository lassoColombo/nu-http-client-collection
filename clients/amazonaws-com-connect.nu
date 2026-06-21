# Auto-generated client for Amazon Connect Service v2017-08-08
# Source: https://api.apis.guru/v2/specs/amazonaws.com/connect/2017-08-08/openapi.json
# Auth: --token flag or $env.AMAZON_CONNECT_SERVICE_TOKEN

const BASE_URL = "http://connect.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_CONNECT_SERVICE_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["http://connect.us-east-1.amazonaws.com" "http://connect.us-east-2.amazonaws.com" "http://connect.us-west-1.amazonaws.com" "http://connect.us-west-2.amazonaws.com" "http://connect.us-gov-west-1.amazonaws.com" "http://connect.us-gov-east-1.amazonaws.com" "http://connect.ca-central-1.amazonaws.com" "http://connect.eu-north-1.amazonaws.com" "http://connect.eu-west-1.amazonaws.com" "http://connect.eu-west-2.amazonaws.com" "http://connect.eu-west-3.amazonaws.com" "http://connect.eu-central-1.amazonaws.com" "http://connect.eu-south-1.amazonaws.com" "http://connect.af-south-1.amazonaws.com" "http://connect.ap-northeast-1.amazonaws.com" "http://connect.ap-northeast-2.amazonaws.com" "http://connect.ap-northeast-3.amazonaws.com" "http://connect.ap-southeast-1.amazonaws.com" "http://connect.ap-southeast-2.amazonaws.com" "http://connect.ap-east-1.amazonaws.com" "http://connect.ap-south-1.amazonaws.com" "http://connect.sa-east-1.amazonaws.com" "http://connect.me-south-1.amazonaws.com" "https://connect.us-east-1.amazonaws.com" "https://connect.us-east-2.amazonaws.com" "https://connect.us-west-1.amazonaws.com" "https://connect.us-west-2.amazonaws.com" "https://connect.us-gov-west-1.amazonaws.com" "https://connect.us-gov-east-1.amazonaws.com" "https://connect.ca-central-1.amazonaws.com" "https://connect.eu-north-1.amazonaws.com" "https://connect.eu-west-1.amazonaws.com" "https://connect.eu-west-2.amazonaws.com" "https://connect.eu-west-3.amazonaws.com" "https://connect.eu-central-1.amazonaws.com" "https://connect.eu-south-1.amazonaws.com" "https://connect.af-south-1.amazonaws.com" "https://connect.ap-northeast-1.amazonaws.com" "https://connect.ap-northeast-2.amazonaws.com" "https://connect.ap-northeast-3.amazonaws.com" "https://connect.ap-southeast-1.amazonaws.com" "https://connect.ap-southeast-2.amazonaws.com" "https://connect.ap-east-1.amazonaws.com" "https://connect.ap-south-1.amazonaws.com" "https://connect.sa-east-1.amazonaws.com" "https://connect.me-south-1.amazonaws.com" "http://connect.cn-north-1.amazonaws.com.cn" "http://connect.cn-northwest-1.amazonaws.com.cn" "https://connect.cn-north-1.amazonaws.com.cn" "https://connect.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-type-completer [] { ["AGENT_EVENTS" "ATTACHMENTS" "CALL_RECORDINGS" "CHAT_TRANSCRIPTS" "CONTACT_EVALUATIONS" "CONTACT_TRACE_RECORDS" "MEDIA_STREAMS" "REAL_TIME_CONTACT_ANALYSIS_SEGMENTS" "SCHEDULED_REPORTS"] }
def state-completer [] { ["DISABLED" "ENABLED"] }
def type-completer [] { ["AGENT_HOLD" "AGENT_TRANSFER" "AGENT_WHISPER" "CONTACT_FLOW" "CUSTOMER_HOLD" "CUSTOMER_QUEUE" "CUSTOMER_WHISPER" "OUTBOUND_WHISPER" "QUEUE_TRANSFER"] }
def identity-management-type-completer [] { ["CONNECT_MANAGED" "EXISTING_DIRECTORY" "SAML"] }
def integration-type-completer [] { ["CASES_DOMAIN" "EVENT" "PINPOINT_APP" "VOICE_ID" "WISDOM_ASSISTANT" "WISDOM_KNOWLEDGE_BASE"] }
def source-type-completer [] { ["SALESFORCE" "ZENDESK"] }
def publish-status-completer [] { ["DRAFT" "PUBLISHED"] }
def event-source-name-completer [] { ["OnPostCallAnalysisAvailable" "OnPostChatAnalysisAvailable" "OnRealTimeCallAnalysisAvailable" "OnSalesforceCaseCreate" "OnZendeskTicketCreate" "OnZendeskTicketStatusUpdate"] }
def status-completer [] { ["ACTIVE" "INACTIVE"] }
def use-case-type-completer [] { ["CONNECT_CAMPAIGNS" "RULES_EVALUATION"] }
def language-code-completer [] { ["ar-AE" "de-CH" "de-DE" "en-AB" "en-AU" "en-GB" "en-IE" "en-IN" "en-NZ" "en-US" "en-WL" "en-ZA" "es-ES" "es-US" "fr-CA" "fr-FR" "hi-IN" "it-IT" "ja-JP" "ko-KR" "pt-BR" "pt-PT" "zh-CN"] }
def lex-version-completer [] { ["V1" "V2"] }
def state-completer-1 [] { ["ACTIVE" "ARCHIVED"] }
def phone-number-country-code-completer [] { ["AD" "AE" "AF" "AG" "AI" "AL" "AM" "AN" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BR" "BS" "BT" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GG" "GH" "GI" "GL" "GM" "GN" "GQ" "GR" "GT" "GU" "GW" "GY" "HK" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW"] }
def phone-number-type-completer [] { ["DID" "TOLL_FREE"] }
def state-completer-2 [] { ["ACTIVE" "CREATION_FAILED" "CREATION_IN_PROGRESS" "DELETE_IN_PROGRESS"] }
def traffic-type-completer [] { ["CAMPAIGN" "GENERAL"] }
def contact-flow-state-completer [] { ["ACTIVE" "ARCHIVED"] }
def status-completer-1 [] { ["DISABLED" "ENABLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "instance-approved-origin update-associate" } } | get name | first)
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

# This API is in preview release for Amazon Connect and is subject to change. Associates an approved origin to an Amazon Connect instance.
#
# PUT /instance/{InstanceId}/approved-origin
# operationId: AssociateApprovedOrigin
export def "instance-approved-origin update-associate" [
  instance_id: string
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
  origin: string # The domain to add to your allow list.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/approved-origin"))
  let req_body = {"Origin": $origin} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Allows the specified Amazon Connect instance to access the specified Amazon Lex or Amazon Lex V2 bot.
#
# PUT /instance/{InstanceId}/bot
# operationId: AssociateBot
# --LexBot shape: {Name?: any, LexRegion?: any}
# --LexV2Bot shape: {AliasArn?: any}
export def "instance-bot update-associate" [
  instance_id: string
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
  --lex-bot: record # Configuration information of an Amazon Lex bot. — shape: {Name?: any, LexRegion?: any}
  --lex-v2-bot: record # Configuration information of an Amazon Lex V2 bot. — shape: {AliasArn?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/bot"))
  let req_body = {"LexBot": $lex_bot, "LexV2Bot": $lex_v2_bot} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Revokes authorization from the specified instance to access the specified Amazon Lex or Amazon Lex V2 bot.
#
# POST /instance/{InstanceId}/bot
# operationId: DisassociateBot
# --LexBot shape: {Name?: any, LexRegion?: any}
# --LexV2Bot shape: {AliasArn?: any}
export def "instance-bot create-disassociate" [
  instance_id: string
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
  --lex-bot: record # Configuration information of an Amazon Lex bot. — shape: {Name?: any, LexRegion?: any}
  --lex-v2-bot: record # Configuration information of an Amazon Lex V2 bot. — shape: {AliasArn?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/bot"))
  let req_body = {"LexBot": $lex_bot, "LexV2Bot": $lex_v2_bot} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Associates an existing vocabulary as the default. Contact Lens for Amazon Connect uses the vocabulary in post-call and real-time analysis sessions for the given language.
#
# PUT /default-vocabulary/{InstanceId}/{LanguageCode}
# operationId: AssociateDefaultVocabulary
export def "default-vocabulary update-associate" [
  instance_id: string
  language_code: string
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
  --vocabulary-id: string # The identifier of the custom vocabulary. If this is empty, the default is set to none.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($language_code | is-empty) { error make --unspanned { msg: "path parameter 'LanguageCode' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), language_code: (encode-path-segment $language_code)} | format pattern "/default-vocabulary/{instance_id}/{language_code}"))
  let req_body = {"VocabularyId": $vocabulary_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Associates a storage resource type for the first time. You can only associate one type of storage configuration in a single call. This means, for example, that you can't define an instance with multiple S3 buckets for storing chat transcripts. This API does not create a resource that doesn't exist. It only associates it to the instance. Ensure that the resource being specified in the storage configuration, like an S3 bucket, exists when being used for association.
#
# PUT /instance/{InstanceId}/storage-config
# operationId: AssociateInstanceStorageConfig
# --StorageConfig shape: {AssociationId?: any, StorageType?: any, S3Config?: any, KinesisVideoStreamConfig?: any, KinesisStreamConfig?: any, KinesisFirehoseConfig?: any}
export def "instance-storage-config update-associate" [
  instance_id: string
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
  resource_type: string@resource-type-completer # A valid resource type.
  storage_config: record # The storage configuration for the instance. — shape: {AssociationId?: any, StorageType?: any, S3Config?: any, KinesisVideoStreamConfig?: any, KinesisStreamConfig?: any, KinesisFirehoseConfig?: any}
]: any -> record<AssociationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/storage-config"))
  let req_body = {"ResourceType": $resource_type, "StorageConfig": $storage_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Allows the specified Amazon Connect instance to access the specified Lambda function.
#
# PUT /instance/{InstanceId}/lambda-function
# operationId: AssociateLambdaFunction
export def "instance-lambda-function update-associate" [
  instance_id: string
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
  function_arn: string # The Amazon Resource Name (ARN) for the Lambda function being associated. Maximum number of characters allowed is 140.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/lambda-function"))
  let req_body = {"FunctionArn": $function_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Allows the specified Amazon Connect instance to access the specified Amazon Lex V1 bot. This API only supports the association of Amazon Lex V1 bots.
#
# PUT /instance/{InstanceId}/lex-bot
# operationId: AssociateLexBot
# --LexBot shape: {Name?: any, LexRegion?: any}
export def "instance-lex-bot update-associate" [
  instance_id: string
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
  lex_bot: record # Configuration information of an Amazon Lex bot. — shape: {Name?: any, LexRegion?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/lex-bot"))
  let req_body = {"LexBot": $lex_bot} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Associates a flow with a phone number claimed to your Amazon Connect instance. If the number is claimed to a traffic distribution group, and you are calling this API using an instance in the Amazon Web Services Region where the traffic distribution group was created, you can use either a full phone number ARN or UUID value for the PhoneNumberId URI request parameter. However, if the number is claimed to a traffic distribution group and you are calling this API using an instance in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# PUT /phone-number/{PhoneNumberId}/contact-flow
# operationId: AssociatePhoneNumberContactFlow
export def "phone-number-contact-flow update-associate" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_flow_id: string # The identifier of the flow.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'PhoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone-number/{phone_number_id}/contact-flow"))
  let req_body = {"InstanceId": $instance_id, "ContactFlowId": $contact_flow_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Associates a set of quick connects with a queue.
#
# POST /queues/{InstanceId}/{QueueId}/associate-quick-connects
# operationId: AssociateQueueQuickConnects
export def "queues-associate-quick-connects create" [
  instance_id: string
  queue_id: string
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
  quick_connect_ids: list<string> # The quick connects to associate with this queue.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'QueueId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/queues/{instance_id}/{queue_id}/associate-quick-connects"))
  let req_body = {"QuickConnectIds": $quick_connect_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Associates a set of queues with a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/associate-queues
# operationId: AssociateRoutingProfileQueues
# --QueueConfigs item shape: {QueueReference: any, Priority: any, Delay: any}
export def "routing-profiles-associate-queues create" [
  instance_id: string
  routing_profile_id: string
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
  queue_configs: list # The queues to associate with this routing profile. — item shape: {QueueReference: any, Priority: any, Delay: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($routing_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'RoutingProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), routing_profile_id: (encode-path-segment $routing_profile_id)} | format pattern "/routing-profiles/{instance_id}/{routing_profile_id}/associate-queues"))
  let req_body = {"QueueConfigs": $queue_configs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Associates a security key to the instance.
#
# PUT /instance/{InstanceId}/security-key
# operationId: AssociateSecurityKey
export def "instance-security-key update-associate" [
  instance_id: string
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
  key: string # A valid security key in PEM format.
]: any -> record<AssociationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/security-key"))
  let req_body = {"Key": $key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Claims an available phone number to your Amazon Connect instance or traffic distribution group. You can call this API only in the same Amazon Web Services Region where the Amazon Connect instance or traffic distribution group was created. For more information about how to use this operation, see Claim a phone number in your country (https://docs.aws.amazon.com/connect/latest/adminguide/claim-phone-number.html) and Claim phone numbers to traffic distribution groups (https://docs.aws.amazon.com/connect/latest/adminguide/claim-phone-numbers-traffic-distribution-groups.html) in the Amazon Connect Administrator Guide. You can call the SearchAvailablePhoneNumbers (https://docs.aws.amazon.com/connect/latest/APIReference/API_SearchAvailablePhoneNumbers.html) API for available phone numbers that you can claim. Call the DescribePhoneNumber (https://docs.aws.amazon.com/connect/latest/APIReference/API_DescribePhoneNumber.html) API to verify the status of a previous ClaimPhoneNumber (https://docs.aws.amazon.com/connect/latest/APIReference/API_ClaimPhoneNumber.html) operation.
#
# POST /phone-number/claim
# operationId: ClaimPhoneNumber
export def "phone-number-claim create" [
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
  target_arn: string # The Amazon Resource Name (ARN) for Amazon Connect instances or traffic distribution groups that phone numbers are claimed to.
  phone_number: string # The phone number you want to claim. Phone numbers are formatted [+] [country code] [subscriber number including area code].
  --phone-number-description: string # The description of the phone number.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). Pattern: ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$
]: any -> record<PhoneNumberId: record, PhoneNumberArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone-number/claim")
  let req_body = {"TargetArn": $target_arn, "PhoneNumber": $phone_number, "PhoneNumberDescription": $phone_number_description, "Tags": $tags, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Creates an agent status for the specified Amazon Connect instance.
#
# PUT /agent-status/{InstanceId}
# operationId: CreateAgentStatus
export def "agent-status create" [
  instance_id: string
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
  name: string # The name of the status.
  --description: string # The description of the status.
  state: string@state-completer # The state of the status.
  --display-order: int # The display order of the status.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<AgentStatusARN: record, AgentStatusId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/agent-status/{instance_id}"))
  let req_body = {"Name": $name, "Description": $description, "State": $state, "DisplayOrder": $display_order, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Lists agent statuses.
#
# GET /agent-status/{InstanceId}
# operationId: ListAgentStatuses
export def "agent-status list-statuses" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --agent-status-types: list # Available agent status types.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, AgentStatusSummaryList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "AgentStatusTypes" $agent_status_types "multi") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/agent-status/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "AgentStatusTypes": $agent_status_types, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a flow for the specified Amazon Connect instance. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html).
#
# PUT /contact-flows/{InstanceId}
# operationId: CreateContactFlow
export def "contact-flows create" [
  instance_id: string
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
  name: string # The name of the flow.
  type: string@type-completer # The type of the flow. For descriptions of the available types, see Choose a flow type (https://docs.aws.amazon.com/connect/latest/adminguide/create-contact-flow.html#contact-flow-types) in the Amazon Connect Administrator Guide.
  --description: string # The description of the flow.
  content: string # The content of the flow.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<ContactFlowId: record, ContactFlowArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/contact-flows/{instance_id}"))
  let req_body = {"Name": $name, "Type": $type, "Description": $description, "Content": $content, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a flow module for the specified Amazon Connect instance.
#
# PUT /contact-flow-modules/{InstanceId}
# operationId: CreateContactFlowModule
export def "contact-flow-modules create" [
  instance_id: string
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
  name: string # The name of the flow module.
  --description: string # The description of the flow module.
  content: string # The content of the flow module.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<Id: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/contact-flow-modules/{instance_id}"))
  let req_body = {"Name": $name, "Description": $description, "Content": $content, "Tags": $tags, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Creates hours of operation.
#
# PUT /hours-of-operations/{InstanceId}
# operationId: CreateHoursOfOperation
# --Config item shape: {Day: any, StartTime: any, EndTime: any}
export def "hours-of-operations create" [
  instance_id: string
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
  name: string # The name of the hours of operation.
  --description: string # The description of the hours of operation.
  time_zone: string # The time zone of the hours of operation.
  config: list # Configuration information for the hours of operation: day, start time, and end time. — item shape: {Day: any, StartTime: any, EndTime: any}
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<HoursOfOperationId: record, HoursOfOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/hours-of-operations/{instance_id}"))
  let req_body = {"Name": $name, "Description": $description, "TimeZone": $time_zone, "Config": $config, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Initiates an Amazon Connect instance with all the supported channels enabled. It does not attach any storage, such as Amazon Simple Storage Service (Amazon S3) or Amazon Kinesis. It also does not allow for any configurations on features, such as Contact Lens for Amazon Connect. Amazon Connect enforces a limit on the total number of instances that you can create or delete in 30 days. If you exceed this limit, you will get an error message indicating there has been an excessive number of attempts at creating or deleting instances. You must wait 30 days before you can restart creating and deleting instances in your account.
#
# PUT /instance
# operationId: CreateInstance
export def "instance create" [
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
  --client-token: string # The idempotency token.
  identity_management_type: string@identity-management-type-completer # The type of identity management for your Amazon Connect users.
  --instance-alias: string # The name for your instance. (format: password)
  --directory-id: string # The identifier for the directory.
  --inbound-calls-enabled: oneof<nothing, bool> # Your contact center handles incoming contacts.
  --outbound-calls-enabled: oneof<nothing, bool> # Your contact center allows outbound calls.
]: any -> record<Id: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance")
  let req_body = {"ClientToken": $client_token, "IdentityManagementType": $identity_management_type, "InstanceAlias": $instance_alias, "DirectoryId": $directory_id, "InboundCallsEnabled": $inbound_calls_enabled, "OutboundCallsEnabled": $outbound_calls_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Return a list of instances which are in active state, creation-in-progress state, and failed state. Instances that aren't successfully created (they are in a failed state) are returned only for 24 hours after the CreateInstance API was invoked.
#
# GET /instance
# operationId: ListInstances
export def "instance list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<InstanceSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/instance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates an Amazon Web Services resource association with an Amazon Connect instance.
#
# PUT /instance/{InstanceId}/integration-associations
# operationId: CreateIntegrationAssociation
export def "instance-integration-associations create" [
  instance_id: string
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
  integration_type: string@integration-type-completer # The type of information to be ingested.
  integration_arn: string # The Amazon Resource Name (ARN) of the integration. When integrating with Amazon Pinpoint, the Amazon Connect and Amazon Pinpoint instances must be in the same account.
  --source-application-url: string # The URL for the external application. This field is only required for the EVENT integration type.
  --source-application-name: string # The name of the external application. This field is only required for the EVENT integration type.
  --source-type: string@source-type-completer # The type of the data source. This field is only required for the EVENT integration type.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<IntegrationAssociationId: record, IntegrationAssociationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/integration-associations"))
  let req_body = {"IntegrationType": $integration_type, "IntegrationArn": $integration_arn, "SourceApplicationUrl": $source_application_url, "SourceApplicationName": $source_application_name, "SourceType": $source_type, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Provides summary information about the Amazon Web Services resource associations for the specified Amazon Connect instance.
#
# GET /instance/{InstanceId}/integration-associations
# operationId: ListIntegrationAssociations
export def "instance-integration-associations list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --integration-type: string@integration-type-completer # The integration type.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<IntegrationAssociationSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "integrationType" $integration_type "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/integration-associations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"integrationType": $integration_type, "nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Adds a new participant into an on-going chat contact. For more information, see Customize chat flow experiences by integrating custom participants (https://docs.aws.amazon.com/connect/latest/adminguide/chat-customize-flow.html).
#
# POST /contact/create-participant
# operationId: CreateParticipant
# --ParticipantDetails shape: {ParticipantRole?: any, DisplayName?: any}
export def "contact-create-participant create" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact in this instance of Amazon Connect. Only contacts in the CHAT channel are supported.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  participant_details: record # The details to add for the participant. — shape: {ParticipantRole?: any, DisplayName?: any}
]: any -> record<ParticipantCredentials: record<ParticipantToken: record, Expiry: record>, ParticipantId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/create-participant")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "ClientToken": $client_token, "ParticipantDetails": $participant_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Creates a new queue for the specified Amazon Connect instance. If the number being used in the input is claimed to a traffic distribution group, and you are calling this API using an instance in the Amazon Web Services Region where the traffic distribution group was created, you can use either a full phone number ARN or UUID value for the OutboundCallerIdNumberId value of the OutboundCallerConfig (https://docs.aws.amazon.com/connect/latest/APIReference/API_OutboundCallerConfig) request body parameter. However, if the number is claimed to a traffic distribution group and you are calling this API using an instance in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# PUT /queues/{InstanceId}
# operationId: CreateQueue
# --OutboundCallerConfig shape: {OutboundCallerIdName?: any, OutboundCallerIdNumberId?: any, OutboundFlowId?: any}
export def "queues create" [
  instance_id: string
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
  name: string # The name of the queue.
  --description: string # The description of the queue.
  --outbound-caller-config: record # The outbound caller ID name, number, and outbound whisper flow. — shape: {OutboundCallerIdName?: any, OutboundCallerIdNumberId?: any, OutboundFlowId?: any}
  hours_of_operation_id: string # The identifier for the hours of operation.
  --max-contacts: int # The maximum number of contacts that can be in the queue before it is considered full.
  --quick-connect-ids: list<string> # The quick connects available to agents who are working the queue.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<QueueArn: record, QueueId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/queues/{instance_id}"))
  let req_body = {"Name": $name, "Description": $description, "OutboundCallerConfig": $outbound_caller_config, "HoursOfOperationId": $hours_of_operation_id, "MaxContacts": $max_contacts, "QuickConnectIds": $quick_connect_ids, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a quick connect for the specified Amazon Connect instance.
#
# PUT /quick-connects/{InstanceId}
# operationId: CreateQuickConnect
# --QuickConnectConfig shape: {QuickConnectType?: any, UserConfig?: any, QueueConfig?: any, PhoneConfig?: any}
export def "quick-connects create" [
  instance_id: string
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
  name: string # The name of the quick connect.
  --description: string # The description of the quick connect.
  quick_connect_config: record # Contains configuration settings for a quick connect. — shape: {QuickConnectType?: any, UserConfig?: any, QueueConfig?: any, PhoneConfig?: any}
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<QuickConnectARN: record, QuickConnectId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/quick-connects/{instance_id}"))
  let req_body = {"Name": $name, "Description": $description, "QuickConnectConfig": $quick_connect_config, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Provides information about the quick connects for the specified Amazon Connect instance.
#
# GET /quick-connects/{InstanceId}
# operationId: ListQuickConnects
export def "quick-connects list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --quick-connect-types: list # The type of quick connect. In the Amazon Connect console, when you create a quick connect, you are prompted to assign one of the following types: Agent (USER), External (PHONE_NUMBER), or Queue (QUEUE).
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<QuickConnectSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "QuickConnectTypes" $quick_connect_types "multi") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/quick-connects/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "QuickConnectTypes": $quick_connect_types, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a new routing profile.
#
# PUT /routing-profiles/{InstanceId}
# operationId: CreateRoutingProfile
# --QueueConfigs item shape: {QueueReference: any, Priority: any, Delay: any}
# --MediaConcurrencies item shape: {Channel: any, Concurrency: any, CrossChannelBehavior?: any}
export def "routing-profiles create" [
  instance_id: string
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
  name: string # The name of the routing profile. Must not be more than 127 characters.
  description: string # Description of the routing profile. Must not be more than 250 characters.
  default_outbound_queue_id: string # The default outbound queue for the routing profile.
  --queue-configs: list # The inbound queues associated with the routing profile. If no queue is added, the agent can make only outbound calls. The limit of 10 array members applies to the maximum number of RoutingProfileQueueConfig objects that can be passed during a CreateRoutingProfile API request. It is different from the quota of 50 queues per routing profile per instance that is listed in Amazon Connect service quotas (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html). — item shape: {QueueReference: any, Priority: any, Delay: any}
  media_concurrencies: list # The channels that agents can handle in the Contact Control Panel (CCP) for this routing profile. — item shape: {Channel: any, Concurrency: any, CrossChannelBehavior?: any}
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<RoutingProfileArn: record, RoutingProfileId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/routing-profiles/{instance_id}"))
  let req_body = {"Name": $name, "Description": $description, "DefaultOutboundQueueId": $default_outbound_queue_id, "QueueConfigs": $queue_configs, "MediaConcurrencies": $media_concurrencies, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a rule for the specified Amazon Connect instance. Use the Rules Function language (https://docs.aws.amazon.com/connect/latest/APIReference/connect-rules-language.html) to code conditions for the rule.
#
# POST /rules/{InstanceId}
# operationId: CreateRule
# --TriggerEventSource shape: {EventSourceName?: any, IntegrationAssociationId?: any}
# --Actions item shape: {ActionType: any, TaskAction?: any, EventBridgeAction?: any, AssignContactCategoryAction?: any, SendNotificationAction?: any}
export def "rules create" [
  instance_id: string
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
  name: string # A unique name for the rule.
  trigger_event_source: record # The name of the event source. This field is required if TriggerEventSource is one of the following values: OnZendeskTicketCreate | OnZendeskTicketStatusUpdate | OnSalesforceCaseCreate — shape: {EventSourceName?: any, IntegrationAssociationId?: any}
  function: string # The conditions of the rule.
  actions: list # A list of actions to be run when the rule is triggered. — item shape: {ActionType: any, TaskAction?: any, EventBridgeAction?: any, AssignContactCategoryAction?: any, SendNotificationAction?: any}
  publish_status: string@publish-status-completer # The publish status of the rule.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<RuleArn: record, RuleId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/rules/{instance_id}"))
  let req_body = {"Name": $name, "TriggerEventSource": $trigger_event_source, "Function": $function, "Actions": $actions, "PublishStatus": $publish_status, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all rules for the specified Amazon Connect instance.
#
# GET /rules/{InstanceId}
# operationId: ListRules
export def "rules list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --publish-status: string@publish-status-completer # The publish status of the rule.
  --event-source-name: string@event-source-name-completer # The name of the event source.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RuleSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "publishStatus" $publish_status "scalar") (serialize-qp "eventSourceName" $event_source_name "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/rules/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"publishStatus": $publish_status, "eventSourceName": $event_source_name, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Creates a security profile.
#
# PUT /security-profiles/{InstanceId}
# operationId: CreateSecurityProfile
export def "security-profiles create" [
  instance_id: string
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
  security_profile_name: string # The name of the security profile.
  --description: string # The description of the security profile.
  --permissions: list<string> # Permissions assigned to the security profile. For a list of valid permissions, see List of security profile permissions (https://docs.aws.amazon.com/connect/latest/adminguide/security-profile-list.html).
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
  --allowed-access-control-tags: record # The list of tags that a security profile uses to restrict access to resources in Amazon Connect.
  --tag-restricted-resources: list<string> # The list of resources that a security profile applies tag restrictions to in Amazon Connect. Following are acceptable ResourceNames: User | SecurityProfile | Queue | RoutingProfile
]: any -> record<SecurityProfileId: record, SecurityProfileArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/security-profiles/{instance_id}"))
  let req_body = {"SecurityProfileName": $security_profile_name, "Description": $description, "Permissions": $permissions, "Tags": $tags, "AllowedAccessControlTags": $allowed_access_control_tags, "TagRestrictedResources": $tag_restricted_resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new task template in the specified Amazon Connect instance.
#
# PUT /instance/{InstanceId}/task/template
# operationId: CreateTaskTemplate
# --Constraints shape: {RequiredFields?: any, ReadOnlyFields?: any, InvisibleFields?: any}
# --Defaults shape: {DefaultFieldValues?: any}
# --Fields item shape: {Id: any, Description?: any, Type?: any, SingleSelectOptions?: any}
export def "instance-task-template create" [
  instance_id: string
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
  name: string # The name of the task template.
  --description: string # The description of the task template.
  --contact-flow-id: string # The identifier of the flow that runs by default when a task is created by referencing this template.
  --constraints: record # Describes constraints that apply to the template fields. — shape: {RequiredFields?: any, ReadOnlyFields?: any, InvisibleFields?: any}
  --defaults: record # Describes default values for fields on a template. — shape: {DefaultFieldValues?: any}
  --status: string@status-completer # Marks a template as ACTIVE or INACTIVE for a task to refer to it. Tasks can only be created from ACTIVE templates. If a template is marked as INACTIVE, then a task that refers to this template cannot be created.
  fields: list # Fields that are part of the template. — item shape: {Id: any, Description?: any, Type?: any, SingleSelectOptions?: any}
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<Id: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/task/template"))
  let req_body = {"Name": $name, "Description": $description, "ContactFlowId": $contact_flow_id, "Constraints": $constraints, "Defaults": $defaults, "Status": $status, "Fields": $fields, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists task templates for the specified Amazon Connect instance.
#
# GET /instance/{InstanceId}/task/template
# operationId: ListTaskTemplates
export def "instance-task-template list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. It is not expected that you set this because the value returned in the previous response is always null.
  --max-results: int # The maximum number of results to return per page. It is not expected that you set this.
  --status: string@status-completer # Marks a template as ACTIVE or INACTIVE for a task to refer to it. Tasks can only be created from ACTIVE templates. If a template is marked as INACTIVE, then a task that refers to this template cannot be created.
  --name: string # The name of the task template.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TaskTemplates: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/task/template") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "status": $status, "name": $name, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a traffic distribution group given an Amazon Connect instance that has been replicated. For more information about creating traffic distribution groups, see Set up traffic distribution groups (https://docs.aws.amazon.com/connect/latest/adminguide/setup-traffic-distribution-groups.html) in the Amazon Connect Administrator Guide.
#
# PUT /traffic-distribution-group
# operationId: CreateTrafficDistributionGroup
export def "traffic-distribution-group create" [
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
  name: string # The name for the traffic distribution group.
  --description: string # A description for the traffic distribution group.
  instance_id: string # The identifier of the Amazon Connect instance that has been replicated. You can find the instanceId in the ARN of the instance.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<Id: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/traffic-distribution-group")
  let req_body = {"Name": $name, "Description": $description, "InstanceId": $instance_id, "ClientToken": $client_token, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a use case for an integration association.
#
# PUT /instance/{InstanceId}/integration-associations/{IntegrationAssociationId}/use-cases
# operationId: CreateUseCase
export def "instance-integration-associations-use-cases create" [
  instance_id: string
  integration_association_id: string
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
  use_case_type: string@use-case-type-completer # The type of use case to associate to the integration association. Each integration association can have only one of each use case type.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<UseCaseId: record, UseCaseArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($integration_association_id | is-empty) { error make --unspanned { msg: "path parameter 'IntegrationAssociationId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), integration_association_id: (encode-path-segment $integration_association_id)} | format pattern "/instance/{instance_id}/integration-associations/{integration_association_id}/use-cases"))
  let req_body = {"UseCaseType": $use_case_type, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the use cases for the integration association.
#
# GET /instance/{InstanceId}/integration-associations/{IntegrationAssociationId}/use-cases
# operationId: ListUseCases
export def "instance-integration-associations-use-cases list" [
  instance_id: string
  integration_association_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UseCaseSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($integration_association_id | is-empty) { error make --unspanned { msg: "path parameter 'IntegrationAssociationId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), integration_association_id: (encode-path-segment $integration_association_id)} | format pattern "/instance/{instance_id}/integration-associations/{integration_association_id}/use-cases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a user account for the specified Amazon Connect instance. For information about how to create user accounts using the Amazon Connect console, see Add Users (https://docs.aws.amazon.com/connect/latest/adminguide/user-management.html) in the Amazon Connect Administrator Guide.
#
# PUT /users/{InstanceId}
# operationId: CreateUser
# --IdentityInfo shape: {FirstName?: any, LastName?: any, Email?: any, SecondaryEmail?: any, Mobile?: any}
# --PhoneConfig shape: {PhoneType?: any, AutoAccept?: any, AfterContactWorkTimeLimit?: any, DeskPhoneNumber?: any}
export def "users create" [
  instance_id: string
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
  username: string # The user name for the account. For instances not using SAML for identity management, the user name can include up to 20 characters. If you are using SAML for identity management, the user name can include up to 64 characters from [a-zA-Z0-9_-.\@]+.
  --password: string # The password for the user account. A password is required if you are using Amazon Connect for identity management. Otherwise, it is an error to include a password.
  --identity-info: record # Contains information about the identity of a user. — shape: {FirstName?: any, LastName?: any, Email?: any, SecondaryEmail?: any, Mobile?: any}
  phone_config: record # Contains information about the phone configuration settings for a user. — shape: {PhoneType?: any, AutoAccept?: any, AfterContactWorkTimeLimit?: any, DeskPhoneNumber?: any}
  --directory-user-id: string # The identifier of the user account in the directory used for identity management. If Amazon Connect cannot access the directory, you can specify this identifier to authenticate users. If you include the identifier, we assume that Amazon Connect cannot access the directory. Otherwise, the identity information is used to authenticate users from your directory. This parameter is required if you are using an existing directory for identity management in Amazon Connect when Amazon Connect cannot access your directory to authenticate users. If you are using SAML for identity management and include this parameter, an error is returned.
  security_profile_ids: list<string> # The identifier of the security profile for the user.
  routing_profile_id: string # The identifier of the routing profile for the user.
  --hierarchy-group-id: string # The identifier of the hierarchy group for the user.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<UserId: record, UserArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/users/{instance_id}"))
  let req_body = {"Username": $username, "Password": $password, "IdentityInfo": $identity_info, "PhoneConfig": $phone_config, "DirectoryUserId": $directory_user_id, "SecurityProfileIds": $security_profile_ids, "RoutingProfileId": $routing_profile_id, "HierarchyGroupId": $hierarchy_group_id, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new user hierarchy group.
#
# PUT /user-hierarchy-groups/{InstanceId}
# operationId: CreateUserHierarchyGroup
export def "user-hierarchy-groups create" [
  instance_id: string
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
  name: string # The name of the user hierarchy group. Must not be more than 100 characters.
  --parent-group-id: string # The identifier for the parent hierarchy group. The user hierarchy is created at level one if the parent group ID is null.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<HierarchyGroupId: record, HierarchyGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/user-hierarchy-groups/{instance_id}"))
  let req_body = {"Name": $name, "ParentGroupId": $parent_group_id, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a custom vocabulary associated with your Amazon Connect instance. You can set a custom vocabulary to be your default vocabulary for a given language. Contact Lens for Amazon Connect uses the default vocabulary in post-call and real-time contact analysis sessions for that language.
#
# POST /vocabulary/{InstanceId}
# operationId: CreateVocabulary
export def "vocabulary create" [
  instance_id: string
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
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). If a create request is received more than once with same client token, subsequent requests return the previous response without creating a vocabulary again.
  vocabulary_name: string # A unique name of the custom vocabulary.
  language_code: string@language-code-completer # The language code of the vocabulary entries. For a list of languages and their corresponding language codes, see What is Amazon Transcribe? (https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-whatis.html)
  content: string # The content of the custom vocabulary in plain-text format with a table of values. Each row in the table represents a word or a phrase, described with Phrase, IPA, SoundsLike, and DisplayAs fields. Separate the fields with TAB characters. The size limit is 50KB. For more information, see Create a custom vocabulary using a table (https://docs.aws.amazon.com/transcribe/latest/dg/custom-vocabulary.html#create-vocabulary-table).
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> record<VocabularyArn: record, VocabularyId: record, State: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/vocabulary/{instance_id}"))
  let req_body = {"ClientToken": $client_token, "VocabularyName": $vocabulary_name, "LanguageCode": $language_code, "Content": $content, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a flow for the specified Amazon Connect instance.
#
# DELETE /contact-flows/{InstanceId}/{ContactFlowId}
# operationId: DeleteContactFlow
export def "contact-flows delete" [
  instance_id: string
  contact_flow_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_flow_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactFlowId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_flow_id: (encode-path-segment $contact_flow_id)} | format pattern "/contact-flows/{instance_id}/{contact_flow_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes the specified flow. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html).
#
# GET /contact-flows/{InstanceId}/{ContactFlowId}
# operationId: DescribeContactFlow
export def "contact-flows get" [
  instance_id: string
  contact_flow_id: string
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
]: nothing -> record<ContactFlow: record<Arn: record, Id: record, Name: record, Type: record, State: record, Description: record, Content: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_flow_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactFlowId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_flow_id: (encode-path-segment $contact_flow_id)} | format pattern "/contact-flows/{instance_id}/{contact_flow_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes the specified flow module.
#
# DELETE /contact-flow-modules/{InstanceId}/{ContactFlowModuleId}
# operationId: DeleteContactFlowModule
export def "contact-flow-modules delete" [
  instance_id: string
  contact_flow_module_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_flow_module_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactFlowModuleId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_flow_module_id: (encode-path-segment $contact_flow_module_id)} | format pattern "/contact-flow-modules/{instance_id}/{contact_flow_module_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes the specified flow module.
#
# GET /contact-flow-modules/{InstanceId}/{ContactFlowModuleId}
# operationId: DescribeContactFlowModule
export def "contact-flow-modules get" [
  instance_id: string
  contact_flow_module_id: string
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
]: nothing -> record<ContactFlowModule: record<Arn: record, Id: record, Name: record, Content: record, Description: record, State: record, Status: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_flow_module_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactFlowModuleId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_flow_module_id: (encode-path-segment $contact_flow_module_id)} | format pattern "/contact-flow-modules/{instance_id}/{contact_flow_module_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Deletes an hours of operation.
#
# DELETE /hours-of-operations/{InstanceId}/{HoursOfOperationId}
# operationId: DeleteHoursOfOperation
export def "hours-of-operations delete" [
  instance_id: string
  hours_of_operation_id: string
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($hours_of_operation_id | is-empty) { error make --unspanned { msg: "path parameter 'HoursOfOperationId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), hours_of_operation_id: (encode-path-segment $hours_of_operation_id)} | format pattern "/hours-of-operations/{instance_id}/{hours_of_operation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Describes the hours of operation.
#
# GET /hours-of-operations/{InstanceId}/{HoursOfOperationId}
# operationId: DescribeHoursOfOperation
export def "hours-of-operations get" [
  instance_id: string
  hours_of_operation_id: string
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
]: nothing -> record<HoursOfOperation: record<HoursOfOperationId: record, HoursOfOperationArn: record, Name: record, Description: record, TimeZone: record, Config: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($hours_of_operation_id | is-empty) { error make --unspanned { msg: "path parameter 'HoursOfOperationId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), hours_of_operation_id: (encode-path-segment $hours_of_operation_id)} | format pattern "/hours-of-operations/{instance_id}/{hours_of_operation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the hours of operation.
#
# POST /hours-of-operations/{InstanceId}/{HoursOfOperationId}
# operationId: UpdateHoursOfOperation
# --Config item shape: {Day: any, StartTime: any, EndTime: any}
export def "hours-of-operations update" [
  instance_id: string
  hours_of_operation_id: string
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
  --name: string # The name of the hours of operation.
  --description: string # The description of the hours of operation.
  --time-zone: string # The time zone of the hours of operation.
  --config: list # Configuration information of the hours of operation. — item shape: {Day: any, StartTime: any, EndTime: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($hours_of_operation_id | is-empty) { error make --unspanned { msg: "path parameter 'HoursOfOperationId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), hours_of_operation_id: (encode-path-segment $hours_of_operation_id)} | format pattern "/hours-of-operations/{instance_id}/{hours_of_operation_id}"))
  let req_body = {"Name": $name, "Description": $description, "TimeZone": $time_zone, "Config": $config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Deletes the Amazon Connect instance. Amazon Connect enforces a limit on the total number of instances that you can create or delete in 30 days. If you exceed this limit, you will get an error message indicating there has been an excessive number of attempts at creating or deleting instances. You must wait 30 days before you can restart creating and deleting instances in your account.
#
# DELETE /instance/{InstanceId}
# operationId: DeleteInstance
export def "instance delete" [
  instance_id: string
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Returns the current state of the specified instance identifier. It tracks the instance while it is being created and returns an error status, if applicable. If an instance is not created successfully, the instance status reason field returns details relevant to the reason. The instance in a failed state is returned only for 24 hours after the CreateInstance API was invoked.
#
# GET /instance/{InstanceId}
# operationId: DescribeInstance
export def "instance get" [
  instance_id: string
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
]: nothing -> record<Instance: record<Id: record, Arn: record, IdentityManagementType: record, InstanceAlias: record, CreatedTime: record, ServiceRole: record, InstanceStatus: record, StatusReason: record<Message: record>, InboundCallsEnabled: record, OutboundCallsEnabled: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes an Amazon Web Services resource association from an Amazon Connect instance. The association must not have any use cases associated with it.
#
# DELETE /instance/{InstanceId}/integration-associations/{IntegrationAssociationId}
# operationId: DeleteIntegrationAssociation
export def "instance-integration-associations delete" [
  instance_id: string
  integration_association_id: string
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($integration_association_id | is-empty) { error make --unspanned { msg: "path parameter 'IntegrationAssociationId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), integration_association_id: (encode-path-segment $integration_association_id)} | format pattern "/instance/{instance_id}/integration-associations/{integration_association_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a quick connect.
#
# DELETE /quick-connects/{InstanceId}/{QuickConnectId}
# operationId: DeleteQuickConnect
export def "quick-connects delete" [
  instance_id: string
  quick_connect_id: string
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($quick_connect_id | is-empty) { error make --unspanned { msg: "path parameter 'QuickConnectId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), quick_connect_id: (encode-path-segment $quick_connect_id)} | format pattern "/quick-connects/{instance_id}/{quick_connect_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes the quick connect.
#
# GET /quick-connects/{InstanceId}/{QuickConnectId}
# operationId: DescribeQuickConnect
export def "quick-connects get" [
  instance_id: string
  quick_connect_id: string
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
]: nothing -> record<QuickConnect: record<QuickConnectARN: record, QuickConnectId: record, Name: record, Description: record, QuickConnectConfig: record<QuickConnectType: record, UserConfig: record, QueueConfig: record, PhoneConfig: record>, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($quick_connect_id | is-empty) { error make --unspanned { msg: "path parameter 'QuickConnectId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), quick_connect_id: (encode-path-segment $quick_connect_id)} | format pattern "/quick-connects/{instance_id}/{quick_connect_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a rule for the specified Amazon Connect instance.
#
# DELETE /rules/{InstanceId}/{RuleId}
# operationId: DeleteRule
export def "rules delete" [
  instance_id: string
  rule_id: string
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'RuleId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/rules/{instance_id}/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes a rule for the specified Amazon Connect instance.
#
# GET /rules/{InstanceId}/{RuleId}
# operationId: DescribeRule
export def "rules get" [
  instance_id: string
  rule_id: string
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
]: nothing -> record<Rule: record<Name: record, RuleId: record, RuleArn: record, TriggerEventSource: record<EventSourceName: record, IntegrationAssociationId: record>, Function: record, Actions: record, PublishStatus: record, CreatedTime: record, LastUpdatedTime: record, LastUpdatedBy: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'RuleId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/rules/{instance_id}/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a rule for the specified Amazon Connect instance. Use the Rules Function language (https://docs.aws.amazon.com/connect/latest/APIReference/connect-rules-language.html) to code conditions for the rule.
#
# PUT /rules/{InstanceId}/{RuleId}
# operationId: UpdateRule
# --Actions item shape: {ActionType: any, TaskAction?: any, EventBridgeAction?: any, AssignContactCategoryAction?: any, SendNotificationAction?: any}
export def "rules update" [
  instance_id: string
  rule_id: string
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
  name: string # The name of the rule. You can change the name only if TriggerEventSource is one of the following values: OnZendeskTicketCreate | OnZendeskTicketStatusUpdate | OnSalesforceCaseCreate
  function: string # The conditions of the rule.
  actions: list # A list of actions to be run when the rule is triggered. — item shape: {ActionType: any, TaskAction?: any, EventBridgeAction?: any, AssignContactCategoryAction?: any, SendNotificationAction?: any}
  publish_status: string@publish-status-completer # The publish status of the rule.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'RuleId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/rules/{instance_id}/{rule_id}"))
  let req_body = {"Name": $name, "Function": $function, "Actions": $actions, "PublishStatus": $publish_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Deletes a security profile.
#
# DELETE /security-profiles/{InstanceId}/{SecurityProfileId}
# operationId: DeleteSecurityProfile
export def "security-profiles delete" [
  instance_id: string
  security_profile_id: string
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($security_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'SecurityProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), security_profile_id: (encode-path-segment $security_profile_id)} | format pattern "/security-profiles/{instance_id}/{security_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Gets basic information about the security profle.
#
# GET /security-profiles/{InstanceId}/{SecurityProfileId}
# operationId: DescribeSecurityProfile
export def "security-profiles get" [
  instance_id: string
  security_profile_id: string
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
]: nothing -> record<SecurityProfile: record<Id: record, OrganizationResourceId: record, Arn: record, SecurityProfileName: record, Description: record, Tags: record, AllowedAccessControlTags: record, TagRestrictedResources: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($security_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'SecurityProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), security_profile_id: (encode-path-segment $security_profile_id)} | format pattern "/security-profiles/{instance_id}/{security_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates a security profile.
#
# POST /security-profiles/{InstanceId}/{SecurityProfileId}
# operationId: UpdateSecurityProfile
export def "security-profiles update" [
  instance_id: string
  security_profile_id: string
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
  --description: string # The description of the security profile.
  --permissions: list<string> # The permissions granted to a security profile. For a list of valid permissions, see List of security profile permissions (https://docs.aws.amazon.com/connect/latest/adminguide/security-profile-list.html).
  --allowed-access-control-tags: record # The list of tags that a security profile uses to restrict access to resources in Amazon Connect.
  --tag-restricted-resources: list<string> # The list of resources that a security profile applies tag restrictions to in Amazon Connect.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($security_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'SecurityProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), security_profile_id: (encode-path-segment $security_profile_id)} | format pattern "/security-profiles/{instance_id}/{security_profile_id}"))
  let req_body = {"Description": $description, "Permissions": $permissions, "AllowedAccessControlTags": $allowed_access_control_tags, "TagRestrictedResources": $tag_restricted_resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the task template.
#
# DELETE /instance/{InstanceId}/task/template/{TaskTemplateId}
# operationId: DeleteTaskTemplate
export def "instance-task-template delete" [
  instance_id: string
  task_template_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($task_template_id | is-empty) { error make --unspanned { msg: "path parameter 'TaskTemplateId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), task_template_id: (encode-path-segment $task_template_id)} | format pattern "/instance/{instance_id}/task/template/{task_template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets details about a specific task template in the specified Amazon Connect instance.
#
# GET /instance/{InstanceId}/task/template/{TaskTemplateId}
# operationId: GetTaskTemplate
export def "instance-task-template get" [
  instance_id: string
  task_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-version: string # The system generated version of a task template that is associated with a task, when the task is created.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<InstanceId: record, Id: record, Arn: record, Name: record, Description: record, ContactFlowId: record, Constraints: record<RequiredFields: record, ReadOnlyFields: record, InvisibleFields: record>, Defaults: record<DefaultFieldValues: record>, Fields: record, Status: record, LastModifiedTime: record, CreatedTime: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($task_template_id | is-empty) { error make --unspanned { msg: "path parameter 'TaskTemplateId' must be non-empty" } }
  let qp = [(serialize-qp "snapshotVersion" $snapshot_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), task_template_id: (encode-path-segment $task_template_id)} | format pattern "/instance/{instance_id}/task/template/{task_template_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"snapshotVersion": $snapshot_version} | compact), body: null}
}

# Updates details about a specific task template in the specified Amazon Connect instance. This operation does not support partial updates. Instead it does a full update of template content.
#
# POST /instance/{InstanceId}/task/template/{TaskTemplateId}
# operationId: UpdateTaskTemplate
# --Constraints shape: {RequiredFields?: any, ReadOnlyFields?: any, InvisibleFields?: any}
# --Defaults shape: {DefaultFieldValues?: any}
# --Fields item shape: {Id: any, Description?: any, Type?: any, SingleSelectOptions?: any}
export def "instance-task-template update" [
  instance_id: string
  task_template_id: string
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
  --name: string # The name of the task template.
  --description: string # The description of the task template.
  --contact-flow-id: string # The identifier of the flow that runs by default when a task is created by referencing this template.
  --constraints: record # Describes constraints that apply to the template fields. — shape: {RequiredFields?: any, ReadOnlyFields?: any, InvisibleFields?: any}
  --defaults: record # Describes default values for fields on a template. — shape: {DefaultFieldValues?: any}
  --status: string@status-completer # Marks a template as ACTIVE or INACTIVE for a task to refer to it. Tasks can only be created from ACTIVE templates. If a template is marked as INACTIVE, then a task that refers to this template cannot be created.
  --fields: list # Fields that are part of the template. — item shape: {Id: any, Description?: any, Type?: any, SingleSelectOptions?: any}
]: any -> record<InstanceId: record, Id: record, Arn: record, Name: record, Description: record, ContactFlowId: record, Constraints: record<RequiredFields: record, ReadOnlyFields: record, InvisibleFields: record>, Defaults: record<DefaultFieldValues: record>, Fields: record, Status: record, LastModifiedTime: record, CreatedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($task_template_id | is-empty) { error make --unspanned { msg: "path parameter 'TaskTemplateId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), task_template_id: (encode-path-segment $task_template_id)} | format pattern "/instance/{instance_id}/task/template/{task_template_id}"))
  let req_body = {"Name": $name, "Description": $description, "ContactFlowId": $contact_flow_id, "Constraints": $constraints, "Defaults": $defaults, "Status": $status, "Fields": $fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a traffic distribution group. This API can be called only in the Region where the traffic distribution group is created. For more information about deleting traffic distribution groups, see Delete traffic distribution groups (https://docs.aws.amazon.com/connect/latest/adminguide/delete-traffic-distribution-groups.html) in the Amazon Connect Administrator Guide.
#
# DELETE /traffic-distribution-group/{TrafficDistributionGroupId}
# operationId: DeleteTrafficDistributionGroup
export def "traffic-distribution-group delete" [
  traffic_distribution_group_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($traffic_distribution_group_id | is-empty) { error make --unspanned { msg: "path parameter 'TrafficDistributionGroupId' must be non-empty" } }
  let full_url = (build-url $base ({traffic_distribution_group_id: (encode-path-segment $traffic_distribution_group_id)} | format pattern "/traffic-distribution-group/{traffic_distribution_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets details and status of a traffic distribution group.
#
# GET /traffic-distribution-group/{TrafficDistributionGroupId}
# operationId: DescribeTrafficDistributionGroup
export def "traffic-distribution-group get" [
  traffic_distribution_group_id: string
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
]: nothing -> record<TrafficDistributionGroup: record<Id: record, Arn: record, Name: record, Description: record, InstanceArn: record, Status: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($traffic_distribution_group_id | is-empty) { error make --unspanned { msg: "path parameter 'TrafficDistributionGroupId' must be non-empty" } }
  let full_url = (build-url $base ({traffic_distribution_group_id: (encode-path-segment $traffic_distribution_group_id)} | format pattern "/traffic-distribution-group/{traffic_distribution_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a use case from an integration association.
#
# DELETE /instance/{InstanceId}/integration-associations/{IntegrationAssociationId}/use-cases/{UseCaseId}
# operationId: DeleteUseCase
export def "instance-integration-associations-use-cases delete" [
  instance_id: string
  integration_association_id: string
  use_case_id: string
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($integration_association_id | is-empty) { error make --unspanned { msg: "path parameter 'IntegrationAssociationId' must be non-empty" } }
  if ($use_case_id | is-empty) { error make --unspanned { msg: "path parameter 'UseCaseId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), integration_association_id: (encode-path-segment $integration_association_id), use_case_id: (encode-path-segment $use_case_id)} | format pattern "/instance/{instance_id}/integration-associations/{integration_association_id}/use-cases/{use_case_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a user account from the specified Amazon Connect instance. For information about what happens to a user's data when their account is deleted, see Delete Users from Your Amazon Connect Instance (https://docs.aws.amazon.com/connect/latest/adminguide/delete-users.html) in the Amazon Connect Administrator Guide.
#
# DELETE /users/{InstanceId}/{UserId}
# operationId: DeleteUser
export def "users delete" [
  instance_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), user_id: (encode-path-segment $user_id)} | format pattern "/users/{instance_id}/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes the specified user account. You can find the instance ID in the Amazon Connect console (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
#
# GET /users/{InstanceId}/{UserId}
# operationId: DescribeUser
export def "users get" [
  instance_id: string
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
]: nothing -> record<User: record<Id: record, Arn: record, Username: record, IdentityInfo: record<FirstName: record, LastName: record, Email: record, SecondaryEmail: record, Mobile: record>, PhoneConfig: record<PhoneType: record, AutoAccept: record, AfterContactWorkTimeLimit: record, DeskPhoneNumber: record>, DirectoryUserId: record, SecurityProfileIds: record, RoutingProfileId: record, HierarchyGroupId: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), user_id: (encode-path-segment $user_id)} | format pattern "/users/{instance_id}/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes an existing user hierarchy group. It must not be associated with any agents or have any active child groups.
#
# DELETE /user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}
# operationId: DeleteUserHierarchyGroup
export def "user-hierarchy-groups delete" [
  instance_id: string
  hierarchy_group_id: string
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($hierarchy_group_id | is-empty) { error make --unspanned { msg: "path parameter 'HierarchyGroupId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), hierarchy_group_id: (encode-path-segment $hierarchy_group_id)} | format pattern "/user-hierarchy-groups/{instance_id}/{hierarchy_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes the specified hierarchy group.
#
# GET /user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}
# operationId: DescribeUserHierarchyGroup
export def "user-hierarchy-groups get" [
  instance_id: string
  hierarchy_group_id: string
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
]: nothing -> record<HierarchyGroup: record<Id: record, Arn: record, Name: record, LevelId: record, HierarchyPath: record<LevelOne: record, LevelTwo: record, LevelThree: record, LevelFour: record, LevelFive: record>, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($hierarchy_group_id | is-empty) { error make --unspanned { msg: "path parameter 'HierarchyGroupId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), hierarchy_group_id: (encode-path-segment $hierarchy_group_id)} | format pattern "/user-hierarchy-groups/{instance_id}/{hierarchy_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes the vocabulary that has the given identifier.
#
# POST /vocabulary-remove/{InstanceId}/{VocabularyId}
# operationId: DeleteVocabulary
export def "vocabulary-remove delete" [
  instance_id: string
  vocabulary_id: string
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
]: nothing -> record<VocabularyArn: record, VocabularyId: record, State: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($vocabulary_id | is-empty) { error make --unspanned { msg: "path parameter 'VocabularyId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), vocabulary_id: (encode-path-segment $vocabulary_id)} | format pattern "/vocabulary-remove/{instance_id}/{vocabulary_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Describes an agent status.
#
# GET /agent-status/{InstanceId}/{AgentStatusId}
# operationId: DescribeAgentStatus
export def "agent-status get" [
  instance_id: string
  agent_status_id: string
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
]: nothing -> record<AgentStatus: record<AgentStatusARN: record, AgentStatusId: record, Name: record, Description: record, Type: record, DisplayOrder: record, State: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($agent_status_id | is-empty) { error make --unspanned { msg: "path parameter 'AgentStatusId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), agent_status_id: (encode-path-segment $agent_status_id)} | format pattern "/agent-status/{instance_id}/{agent_status_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates agent status.
#
# POST /agent-status/{InstanceId}/{AgentStatusId}
# operationId: UpdateAgentStatus
export def "agent-status update" [
  instance_id: string
  agent_status_id: string
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
  --name: string # The name of the agent status.
  --description: string # The description of the agent status.
  --state: string@state-completer # The state of the agent status.
  --display-order: int # The display order of the agent status.
  --reset-order-number: oneof<nothing, bool> # A number indicating the reset order of the agent status.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($agent_status_id | is-empty) { error make --unspanned { msg: "path parameter 'AgentStatusId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), agent_status_id: (encode-path-segment $agent_status_id)} | format pattern "/agent-status/{instance_id}/{agent_status_id}"))
  let req_body = {"Name": $name, "Description": $description, "State": $state, "DisplayOrder": $display_order, "ResetOrderNumber": $reset_order_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Describes the specified contact. Contact information remains available in Amazon Connect for 24 months, and then it is deleted. Only data from November 12, 2021, and later is returned by this API.
#
# GET /contacts/{InstanceId}/{ContactId}
# operationId: DescribeContact
export def "contacts get" [
  instance_id: string
  contact_id: string
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
]: nothing -> record<Contact: record<Arn: record, Id: record, InitialContactId: record, PreviousContactId: record, InitiationMethod: record, Name: record, Description: record, Channel: record, QueueInfo: record<Id: record, EnqueueTimestamp: record>, AgentInfo: record<Id: record, ConnectedToAgentTimestamp: record>, InitiationTimestamp: record, DisconnectTimestamp: record, LastUpdateTimestamp: record, ScheduledTimestamp: record, RelatedContactId: record, WisdomInfo: record<SessionArn: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_id: (encode-path-segment $contact_id)} | format pattern "/contacts/{instance_id}/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Adds or updates user-defined contact information associated with the specified contact. At least one field to be updated must be present in the request. You can add or update user-defined contact information for both ongoing and completed contacts.
#
# POST /contacts/{InstanceId}/{ContactId}
# operationId: UpdateContact
export def "contacts update" [
  instance_id: string
  contact_id: string
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
  --name: string # The name of the contact.
  --description: string # The description of the contact.
  --references: record # Well-formed data on contact, shown to agents on Contact Control Panel (CCP).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_id: (encode-path-segment $contact_id)} | format pattern "/contacts/{instance_id}/{contact_id}"))
  let req_body = {"Name": $name, "Description": $description, "References": $references} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Describes the specified instance attribute.
#
# GET /instance/{InstanceId}/attribute/{AttributeType}
# operationId: DescribeInstanceAttribute
export def "instance-attribute get" [
  instance_id: string
  attribute_type: string
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
]: nothing -> record<Attribute: record<AttributeType: record, Value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($attribute_type | is-empty) { error make --unspanned { msg: "path parameter 'AttributeType' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), attribute_type: (encode-path-segment $attribute_type)} | format pattern "/instance/{instance_id}/attribute/{attribute_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the value for the specified attribute type.
#
# POST /instance/{InstanceId}/attribute/{AttributeType}
# operationId: UpdateInstanceAttribute
export def "instance-attribute update" [
  instance_id: string
  attribute_type: string
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
  value: string # The value for the attribute. Maximum character limit is 100.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($attribute_type | is-empty) { error make --unspanned { msg: "path parameter 'AttributeType' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), attribute_type: (encode-path-segment $attribute_type)} | format pattern "/instance/{instance_id}/attribute/{attribute_type}"))
  let req_body = {"Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Retrieves the current storage configurations for the specified resource type, association ID, and instance ID.
#
# GET /instance/{InstanceId}/storage-config/{AssociationId}
# operationId: DescribeInstanceStorageConfig
export def "instance-storage-config get" [
  instance_id: string
  association_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer # A valid resource type.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<StorageConfig: record<AssociationId: record, StorageType: record, S3Config: record<BucketName: record, BucketPrefix: record, EncryptionConfig: record>, KinesisVideoStreamConfig: record<Prefix: record, RetentionPeriodHours: record, EncryptionConfig: record>, KinesisStreamConfig: record<StreamArn: record>, KinesisFirehoseConfig: record<FirehoseArn: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($association_id | is-empty) { error make --unspanned { msg: "path parameter 'AssociationId' must be non-empty" } }
  let qp = [(serialize-qp "resourceType" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), association_id: (encode-path-segment $association_id)} | format pattern "/instance/{instance_id}/storage-config/{association_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"resourceType": $resource_type} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Removes the storage type configurations for the specified resource type and association ID.
#
# DELETE /instance/{InstanceId}/storage-config/{AssociationId}
# operationId: DisassociateInstanceStorageConfig
export def "instance-storage-config delete-disassociate" [
  instance_id: string
  association_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer # A valid resource type.
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($association_id | is-empty) { error make --unspanned { msg: "path parameter 'AssociationId' must be non-empty" } }
  let qp = [(serialize-qp "resourceType" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), association_id: (encode-path-segment $association_id)} | format pattern "/instance/{instance_id}/storage-config/{association_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"resourceType": $resource_type} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates an existing configuration for a resource type. This API is idempotent.
#
# POST /instance/{InstanceId}/storage-config/{AssociationId}
# operationId: UpdateInstanceStorageConfig
# --StorageConfig shape: {AssociationId?: any, StorageType?: any, S3Config?: any, KinesisVideoStreamConfig?: any, KinesisStreamConfig?: any, KinesisFirehoseConfig?: any}
export def "instance-storage-config update" [
  instance_id: string
  association_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer # A valid resource type.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  storage_config: record # The storage configuration for the instance. — shape: {AssociationId?: any, StorageType?: any, S3Config?: any, KinesisVideoStreamConfig?: any, KinesisStreamConfig?: any, KinesisFirehoseConfig?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($association_id | is-empty) { error make --unspanned { msg: "path parameter 'AssociationId' must be non-empty" } }
  let qp = [(serialize-qp "resourceType" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), association_id: (encode-path-segment $association_id)} | format pattern "/instance/{instance_id}/storage-config/{association_id}") $qp)
  let req_body = {"StorageConfig": $storage_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"resourceType": $resource_type} | compact), body: $req_body}
}

# Gets details and status of a phone number that’s claimed to your Amazon Connect instance or traffic distribution group. If the number is claimed to a traffic distribution group, and you are calling in the Amazon Web Services Region where the traffic distribution group was created, you can use either a phone number ARN or UUID value for the PhoneNumberId URI request parameter. However, if the number is claimed to a traffic distribution group and you are calling this API in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# GET /phone-number/{PhoneNumberId}
# operationId: DescribePhoneNumber
export def "phone-number get" [
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
]: nothing -> record<ClaimedPhoneNumberSummary: record<PhoneNumberId: record, PhoneNumberArn: record, PhoneNumber: record, PhoneNumberCountryCode: record, PhoneNumberType: record, PhoneNumberDescription: record, TargetArn: record, Tags: record, PhoneNumberStatus: record<Status: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'PhoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone-number/{phone_number_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Releases a phone number previously claimed to an Amazon Connect instance or traffic distribution group. You can call this API only in the Amazon Web Services Region where the number was claimed. To release phone numbers from a traffic distribution group, use the ReleasePhoneNumber API, not the Amazon Connect console. After releasing a phone number, the phone number enters into a cooldown period of 30 days. It cannot be searched for or claimed again until the period has ended. If you accidentally release a phone number, contact Amazon Web Services Support.
#
# DELETE /phone-number/{PhoneNumberId}
# operationId: ReleasePhoneNumber
export def "phone-number delete-release" [
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
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
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
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'PhoneNumberId' must be non-empty" } }
  let qp = [(serialize-qp "clientToken" $client_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone-number/{phone_number_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"clientToken": $client_token} | compact), body: null}
}

# Updates your claimed phone number from its current Amazon Connect instance or traffic distribution group to another Amazon Connect instance or traffic distribution group in the same Amazon Web Services Region. You can call DescribePhoneNumber (https://docs.aws.amazon.com/connect/latest/APIReference/API_DescribePhoneNumber.html) API to verify the status of a previous UpdatePhoneNumber (https://docs.aws.amazon.com/connect/latest/APIReference/API_UpdatePhoneNumber.html) operation.
#
# PUT /phone-number/{PhoneNumberId}
# operationId: UpdatePhoneNumber
export def "phone-number update" [
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
  target_arn: string # The Amazon Resource Name (ARN) for Amazon Connect instances or traffic distribution groups that phone numbers are claimed to.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<PhoneNumberId: record, PhoneNumberArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'PhoneNumberId' must be non-empty" } }
  let full_url = (build-url $base ({phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone-number/{phone_number_id}"))
  let req_body = {"TargetArn": $target_arn, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Describes the specified queue.
#
# GET /queues/{InstanceId}/{QueueId}
# operationId: DescribeQueue
export def "queues get" [
  instance_id: string
  queue_id: string
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
]: nothing -> record<Queue: record<Name: record, QueueArn: record, QueueId: record, Description: record, OutboundCallerConfig: record<OutboundCallerIdName: record, OutboundCallerIdNumberId: record, OutboundFlowId: record>, HoursOfOperationId: record, MaxContacts: record, Status: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'QueueId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/queues/{instance_id}/{queue_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes the specified routing profile.
#
# GET /routing-profiles/{InstanceId}/{RoutingProfileId}
# operationId: DescribeRoutingProfile
export def "routing-profiles get" [
  instance_id: string
  routing_profile_id: string
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
]: nothing -> record<RoutingProfile: record<InstanceId: record, Name: record, RoutingProfileArn: record, RoutingProfileId: record, Description: record, MediaConcurrencies: record, DefaultOutboundQueueId: record, Tags: record, NumberOfAssociatedQueues: record, NumberOfAssociatedUsers: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($routing_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'RoutingProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), routing_profile_id: (encode-path-segment $routing_profile_id)} | format pattern "/routing-profiles/{instance_id}/{routing_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes the hierarchy structure of the specified Amazon Connect instance.
#
# GET /user-hierarchy-structure/{InstanceId}
# operationId: DescribeUserHierarchyStructure
export def "user-hierarchy-structure get" [
  instance_id: string
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
]: nothing -> record<HierarchyStructure: record<LevelOne: record<Id: record, Arn: record, Name: record>, LevelTwo: record<Id: record, Arn: record, Name: record>, LevelThree: record<Id: record, Arn: record, Name: record>, LevelFour: record<Id: record, Arn: record, Name: record>, LevelFive: record<Id: record, Arn: record, Name: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/user-hierarchy-structure/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the user hierarchy structure: add, remove, and rename user hierarchy levels.
#
# POST /user-hierarchy-structure/{InstanceId}
# operationId: UpdateUserHierarchyStructure
# --HierarchyStructure shape: {LevelOne?: any, LevelTwo?: any, LevelThree?: any, LevelFour?: any, LevelFive?: any}
export def "user-hierarchy-structure update" [
  instance_id: string
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
  hierarchy_structure: record # Contains information about the level hierarchy to update. — shape: {LevelOne?: any, LevelTwo?: any, LevelThree?: any, LevelFour?: any, LevelFive?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/user-hierarchy-structure/{instance_id}"))
  let req_body = {"HierarchyStructure": $hierarchy_structure} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Describes the specified vocabulary.
#
# GET /vocabulary/{InstanceId}/{VocabularyId}
# operationId: DescribeVocabulary
export def "vocabulary get" [
  instance_id: string
  vocabulary_id: string
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
]: nothing -> record<Vocabulary: record<Name: record, Id: record, Arn: record, LanguageCode: record, State: record, LastModifiedTime: record, FailureReason: record, Content: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($vocabulary_id | is-empty) { error make --unspanned { msg: "path parameter 'VocabularyId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), vocabulary_id: (encode-path-segment $vocabulary_id)} | format pattern "/vocabulary/{instance_id}/{vocabulary_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Revokes access to integrated applications from Amazon Connect.
#
# DELETE /instance/{InstanceId}/approved-origin
# operationId: DisassociateApprovedOrigin
export def "instance-approved-origin delete-disassociate" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --origin: string # The domain URL of the integrated application.
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "origin" $origin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/approved-origin") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"origin": $origin} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Remove the Lambda function from the dropdown options available in the relevant flow blocks.
#
# DELETE /instance/{InstanceId}/lambda-function
# operationId: DisassociateLambdaFunction
export def "instance-lambda-function delete-disassociate" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --function-arn: string # The Amazon Resource Name (ARN) of the Lambda function being disassociated.
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "functionArn" $function_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/lambda-function") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"functionArn": $function_arn} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Revokes authorization from the specified instance to access the specified Amazon Lex bot.
#
# DELETE /instance/{InstanceId}/lex-bot
# operationId: DisassociateLexBot
export def "instance-lex-bot delete-disassociate" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bot-name: string # The name of the Amazon Lex bot. Maximum character limit of 50.
  --lex-region: string # The Amazon Web Services Region in which the Amazon Lex bot has been created.
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "botName" $bot_name "scalar") (serialize-qp "lexRegion" $lex_region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/lex-bot") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"botName": $bot_name, "lexRegion": $lex_region} | compact), body: null}
}

# Removes the flow association from a phone number claimed to your Amazon Connect instance. If the number is claimed to a traffic distribution group, and you are calling this API using an instance in the Amazon Web Services Region where the traffic distribution group was created, you can use either a full phone number ARN or UUID value for the PhoneNumberId URI request parameter. However, if the number is claimed to a traffic distribution group and you are calling this API using an instance in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# DELETE /phone-number/{PhoneNumberId}/contact-flow
# operationId: DisassociatePhoneNumberContactFlow
export def "phone-number-contact-flow delete-disassociate" [
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
  --instance-id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
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
  if ($phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'PhoneNumberId' must be non-empty" } }
  let qp = [(serialize-qp "instanceId" $instance_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({phone_number_id: (encode-path-segment $phone_number_id)} | format pattern "/phone-number/{phone_number_id}/contact-flow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"instanceId": $instance_id} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Disassociates a set of quick connects from a queue.
#
# POST /queues/{InstanceId}/{QueueId}/disassociate-quick-connects
# operationId: DisassociateQueueQuickConnects
export def "queues-disassociate-quick-connects create" [
  instance_id: string
  queue_id: string
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
  quick_connect_ids: list<string> # The quick connects to disassociate from the queue.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'QueueId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/queues/{instance_id}/{queue_id}/disassociate-quick-connects"))
  let req_body = {"QuickConnectIds": $quick_connect_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disassociates a set of queues from a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/disassociate-queues
# operationId: DisassociateRoutingProfileQueues
# --QueueReferences item shape: {QueueId: any, Channel: any}
export def "routing-profiles-disassociate-queues create" [
  instance_id: string
  routing_profile_id: string
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
  queue_references: list # The queues to disassociate from this routing profile. — item shape: {QueueId: any, Channel: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($routing_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'RoutingProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), routing_profile_id: (encode-path-segment $routing_profile_id)} | format pattern "/routing-profiles/{instance_id}/{routing_profile_id}/disassociate-queues"))
  let req_body = {"QueueReferences": $queue_references} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Deletes the specified security key.
#
# DELETE /instance/{InstanceId}/security-key/{AssociationId}
# operationId: DisassociateSecurityKey
export def "instance-security-key delete-disassociate" [
  instance_id: string
  association_id: string
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
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($association_id | is-empty) { error make --unspanned { msg: "path parameter 'AssociationId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), association_id: (encode-path-segment $association_id)} | format pattern "/instance/{instance_id}/security-key/{association_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Dismisses contacts from an agent’s CCP and returns the agent to an available state, which allows the agent to receive a new routed contact. Contacts can only be dismissed if they are in a MISSED, ERROR, ENDED, or REJECTED state in the Agent Event Stream (https://docs.aws.amazon.com/connect/latest/adminguide/about-contact-states.html).
#
# POST /users/{InstanceId}/{UserId}/contact
# operationId: DismissUserContact
export def "users-contact create-dismiss" [
  instance_id: string
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
  contact_id: string # The identifier of the contact.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), user_id: (encode-path-segment $user_id)} | format pattern "/users/{instance_id}/{user_id}/contact"))
  let req_body = {"ContactId": $contact_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves the contact attributes for the specified contact.
#
# GET /contact/attributes/{InstanceId}/{InitialContactId}
# operationId: GetContactAttributes
export def "contact-attributes get" [
  instance_id: string
  initial_contact_id: string
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
]: nothing -> record<Attributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($initial_contact_id | is-empty) { error make --unspanned { msg: "path parameter 'InitialContactId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), initial_contact_id: (encode-path-segment $initial_contact_id)} | format pattern "/contact/attributes/{instance_id}/{initial_contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the real-time metric data from the specified Amazon Connect instance. For a description of each metric, see Real-time Metrics Definitions (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html) in the Amazon Connect Administrator Guide.
#
# POST /metrics/current/{InstanceId}
# operationId: GetCurrentMetricData
# --Filters shape: {Queues?: any, Channels?: any, RoutingProfiles?: any}
# --CurrentMetrics item shape: {Name?: any, Unit?: any}
# --SortCriteria item shape: {SortByMetric?: "AGENTS_ONLINE"|"AGENTS_AVAILABLE"|"AGENTS_ON_CALL"|"AGENTS_NON_PRODUCTIVE"|"AGENTS_AFTER_CONTACT_WORK"|"AGENTS_ERROR"|"AGENTS_STAFFED"|"CONTACTS_IN_QUEUE"|"OLDEST_CONTACT_AGE"|"CONTACTS_SCHEDULED"|"AGENTS_ON_CONTACT"|"SLOTS_ACTIVE"|"SLOTS_AVAILABLE", SortOrder?: any}
export def "metrics-current get-data" [
  instance_id: string
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
  filters: record # Contains the filter to apply when retrieving metrics. — shape: {Queues?: any, Channels?: any, RoutingProfiles?: any}
  --groupings: list<string> # The grouping applied to the metrics returned. For example, when grouped by QUEUE, the metrics returned apply to each queue rather than aggregated for all queues. If you group by CHANNEL, you should include a Channels filter. VOICE, CHAT, and TASK channels are supported. If you group by ROUTING_PROFILE, you must include either a queue or routing profile filter. In addition, a routing profile filter is required for metrics CONTACTS_SCHEDULED, CONTACTS_IN_QUEUE, and OLDEST_CONTACT_AGE. If no Grouping is included in the request, a summary of metrics is returned.
  current_metrics: list # The metrics to retrieve. Specify the name and unit for each metric. The following metrics are available. For a description of all the metrics, see Real-time Metrics Definitions (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html) in the Amazon Connect Administrator Guide. AGENTS_AFTER_CONTACT_WORK Unit: COUNT Name in real-time metrics report: ACW (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#aftercallwork-real-time) AGENTS_AVAILABLE Unit: COUNT Name in real-time metrics report: Available (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#available-real-time) AGENTS_ERROR Unit: COUNT Name in real-time metrics report: Error (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#error-real-time) AGENTS_NON_PRODUCTIVE Unit: COUNT Name in real-time metrics report: NPT (Non-Productive Time) (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#non-productive-time-real-time) AGENTS_ON_CALL Unit: COUNT Name in real-time metrics report: On contact (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#on-call-real-time) AGENTS_ON_CONTACT Unit: COUNT Name in real-time metrics report: On contact (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#on-call-real-time) AGENTS_ONLINE Unit: COUNT Name in real-time metrics report: Online (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#online-real-time) AGENTS_STAFFED Unit: COUNT Name in real-time metrics report: Staffed (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#staffed-real-time) CONTACTS_IN_QUEUE Unit: COUNT Name in real-time metrics report: In queue (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#in-queue-real-time) CONTACTS_SCHEDULED Unit: COUNT Name in real-time metrics report: Scheduled (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#scheduled-real-time) OLDEST_CONTACT_AGE Unit: SECONDS When you use groupings, Unit says SECONDS and the Value is returned in SECONDS. When you do not use groupings, Unit says SECONDS but the Value is returned in MILLISECONDS. For example, if you get a response like this: { "Metric": { "Name": "OLDEST_CONTACT_AGE", "Unit": "SECONDS" }, "Value": 24113.0 } The actual OLDEST_CONTACT_AGE is 24 seconds. Name in real-time metrics report: Oldest (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#oldest-real-time) SLOTS_ACTIVE Unit: COUNT Name in real-time metrics report: Active (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#active-real-time) SLOTS_AVAILABLE Unit: COUNT Name in real-time metrics report: Availability (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#availability-real-time) — item shape: {Name?: any, Unit?: any}
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. The token expires after 5 minutes from the time it is created. Subsequent requests that use the token must use the same request parameters as the request that generated the token. (body field)
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --sort-criteria: list # The way to sort the resulting response based on metrics. You can enter one sort criteria. By default resources are sorted based on AGENTS_ONLINE, DESCENDING. The metric collection is sorted based on the input metrics. Note the following: Sorting on SLOTS_ACTIVE and SLOTS_AVAILABLE is not supported. — item shape: {SortByMetric?: "AGENTS_ONLINE"|"AGENTS_AVAILABLE"|"AGENTS_ON_CALL"|"AGENTS_NON_PRODUCTIVE"|"AGENTS_AFTER_CONTACT_WORK"|"AGENTS_ERROR"|"AGENTS_STAFFED"|"CONTACTS_IN_QUEUE"|"OLDEST_CONTACT_AGE"|"CONTACTS_SCHEDULED"|"AGENTS_ON_CONTACT"|"SLOTS_ACTIVE"|"SLOTS_AVAILABLE", SortOrder?: any}
]: any -> record<NextToken: record, MetricResults: record, DataSnapshotTime: record, ApproximateTotalCount: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/metrics/current/{instance_id}") $qp)
  let req_body = {"Filters": $filters, "Groupings": $groupings, "CurrentMetrics": $current_metrics, "NextToken": $next_token_body, "MaxResults": $max_results_body, "SortCriteria": $sort_criteria} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Gets the real-time active user data from the specified Amazon Connect instance.
#
# POST /metrics/userdata/{InstanceId}
# operationId: GetCurrentUserData
# --Filters shape: {Queues?: any, ContactFilter?: any, RoutingProfiles?: any, Agents?: any, UserHierarchyGroups?: any}
export def "metrics-userdata get-user-data" [
  instance_id: string
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
  filters: record # A filter for the user data. — shape: {Queues?: any, ContactFilter?: any, RoutingProfiles?: any, Agents?: any, UserHierarchyGroups?: any}
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
  --max-results-body: int # The maximum number of results to return per page. (body field)
]: any -> record<NextToken: record, UserDataList: record, ApproximateTotalCount: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/metrics/userdata/{instance_id}") $qp)
  let req_body = {"Filters": $filters, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Retrieves a token for federation. This API doesn't support root users. If you try to invoke GetFederationToken with root credentials, an error message similar to the following one appears: Provided identity: Principal: .... User: .... cannot be used for federation with Amazon Connect
#
# GET /user/federate/{InstanceId}
# operationId: GetFederationToken
export def "user-federate get-federation-token" [
  instance_id: string
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
]: nothing -> record<Credentials: record<AccessToken: record, AccessTokenExpiration: record, RefreshToken: record, RefreshTokenExpiration: record>, SignInUrl: record, UserArn: record, UserId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/user/federate/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets historical metric data from the specified Amazon Connect instance. For a description of each historical metric, see Historical Metrics Definitions (https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics-definitions.html) in the Amazon Connect Administrator Guide.
#
# POST /metrics/historical/{InstanceId}
# operationId: GetMetricData
# --Filters shape: {Queues?: any, Channels?: any, RoutingProfiles?: any}
# --HistoricalMetrics item shape: {Name?: any, Threshold?: any, Statistic?: any, Unit?: any}
export def "metrics-historical get-data" [
  instance_id: string
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
  start_time: string # The timestamp, in UNIX Epoch time format, at which to start the reporting interval for the retrieval of historical metrics data. The time must be specified using a multiple of 5 minutes, such as 10:05, 10:10, 10:15. The start time cannot be earlier than 24 hours before the time of the request. Historical metrics are available only for 24 hours. (format: date-time)
  end_time: string # The timestamp, in UNIX Epoch time format, at which to end the reporting interval for the retrieval of historical metrics data. The time must be specified using an interval of 5 minutes, such as 11:00, 11:05, 11:10, and must be later than the start time timestamp. The time range between the start and end time must be less than 24 hours. (format: date-time)
  filters: record # Contains the filter to apply when retrieving metrics. — shape: {Queues?: any, Channels?: any, RoutingProfiles?: any}
  --groupings: list<string> # The grouping applied to the metrics returned. For example, when results are grouped by queue, the metrics returned are grouped by queue. The values returned apply to the metrics for each queue rather than aggregated for all queues. If no grouping is specified, a summary of metrics for all queues is returned.
  historical_metrics: list # The metrics to retrieve. Specify the name, unit, and statistic for each metric. The following historical metrics are available. For a description of each metric, see Historical Metrics Definitions (https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics-definitions.html) in the Amazon Connect Administrator Guide. This API does not support a contacts incoming metric (there's no CONTACTS_INCOMING metric missing from the documented list). ABANDON_TIME Unit: SECONDS Statistic: AVG AFTER_CONTACT_WORK_TIME Unit: SECONDS Statistic: AVG API_CONTACTS_HANDLED Unit: COUNT Statistic: SUM CALLBACK_CONTACTS_HANDLED Unit: COUNT Statistic: SUM CONTACTS_ABANDONED Unit: COUNT Statistic: SUM CONTACTS_AGENT_HUNG_UP_FIRST Unit: COUNT Statistic: SUM CONTACTS_CONSULTED Unit: COUNT Statistic: SUM CONTACTS_HANDLED Unit: COUNT Statistic: SUM CONTACTS_HANDLED_INCOMING Unit: COUNT Statistic: SUM CONTACTS_HANDLED_OUTBOUND Unit: COUNT Statistic: SUM CONTACTS_HOLD_ABANDONS Unit: COUNT Statistic: SUM CONTACTS_MISSED Unit: COUNT Statistic: SUM CONTACTS_QUEUED Unit: COUNT Statistic: SUM CONTACTS_TRANSFERRED_IN Unit: COUNT Statistic: SUM CONTACTS_TRANSFERRED_IN_FROM_QUEUE Unit: COUNT Statistic: SUM CONTACTS_TRANSFERRED_OUT Unit: COUNT Statistic: SUM CONTACTS_TRANSFERRED_OUT_FROM_QUEUE Unit: COUNT Statistic: SUM HANDLE_TIME Unit: SECONDS Statistic: AVG HOLD_TIME Unit: SECONDS Statistic: AVG INTERACTION_AND_HOLD_TIME Unit: SECONDS Statistic: AVG INTERACTION_TIME Unit: SECONDS Statistic: AVG OCCUPANCY Unit: PERCENT Statistic: AVG QUEUE_ANSWER_TIME Unit: SECONDS Statistic: AVG QUEUED_TIME Unit: SECONDS Statistic: MAX SERVICE_LEVEL You can include up to 20 SERVICE_LEVEL metrics in a request. Unit: PERCENT Statistic: AVG Threshold: For ThresholdValue, enter any whole number from 1 to 604800 (inclusive), in seconds. For Comparison, you must enter LT (for "Less than"). — item shape: {Name?: any, Threshold?: any, Statistic?: any, Unit?: any}
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
  --max-results-body: int # The maximum number of results to return per page. (body field)
]: any -> record<NextToken: record, MetricResults: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/metrics/historical/{instance_id}") $qp)
  let req_body = {"StartTime": $start_time, "EndTime": $end_time, "Filters": $filters, "Groupings": $groupings, "HistoricalMetrics": $historical_metrics, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Gets metric data from the specified Amazon Connect instance. GetMetricDataV2 offers more features than GetMetricData (https://docs.aws.amazon.com/connect/latest/APIReference/API_GetMetricData.html), the previous version of this API. It has new metrics, offers filtering at a metric level, and offers the ability to filter and group data by channels, queues, routing profiles, agents, and agent hierarchy levels. It can retrieve historical data for the last 14 days, in 24-hour intervals. For a description of the historical metrics that are supported by GetMetricDataV2 and GetMetricData, see Historical metrics definitions (https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics-definitions.html) in the Amazon Connect Administrator's Guide. This API is not available in the Amazon Web Services GovCloud (US) Regions.
#
# POST /metrics/data
# operationId: GetMetricDataV2
# --Filters item shape: {FilterKey?: any, FilterValues?: any}
# --Metrics item shape: {Name?: any, Threshold?: any, MetricFilters?: any}
export def "metrics-data get" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. This includes the instanceId an Amazon Connect instance.
  start_time: string # The timestamp, in UNIX Epoch time format, at which to start the reporting interval for the retrieval of historical metrics data. The time must be before the end time timestamp. The time range between the start and end time must be less than 24 hours. The start time cannot be earlier than 14 days before the time of the request. Historical metrics are available for 14 days. (format: date-time)
  end_time: string # The timestamp, in UNIX Epoch time format, at which to end the reporting interval for the retrieval of historical metrics data. The time must be later than the start time timestamp. It cannot be later than the current timestamp. The time range between the start and end time must be less than 24 hours. (format: date-time)
  filters: list # The filters to apply to returned metrics. You can filter on the following resources: Queues Routing profiles Agents Channels User hierarchy groups At least one filter must be passed from queues, routing profiles, agents, or user hierarchy groups. To filter by phone number, see Create a historical metrics report (https://docs.aws.amazon.com/connect/latest/adminguide/create-historical-metrics-report.html) in the Amazon Connect Administrator's Guide. Note the following limits: Filter keys: A maximum of 5 filter keys are supported in a single request. Valid filter keys: QUEUE | ROUTING_PROFILE | AGENT | CHANNEL | AGENT_HIERARCHY_LEVEL_ONE | AGENT_HIERARCHY_LEVEL_TWO | AGENT_HIERARCHY_LEVEL_THREE | AGENT_HIERARCHY_LEVEL_FOUR | AGENT_HIERARCHY_LEVEL_FIVE Filter values: A maximum of 100 filter values are supported in a single request. For example, a GetMetricDataV2 request can filter by 50 queues, 35 agents, and 15 routing profiles for a total of 100 filter values. VOICE, CHAT, and TASK are valid filterValue for the CHANNEL filter key. — item shape: {FilterKey?: any, FilterValues?: any}
  --groupings: list<string> # The grouping applied to the metrics that are returned. For example, when results are grouped by queue, the metrics returned are grouped by queue. The values that are returned apply to the metrics for each queue. They are not aggregated for all queues. If no grouping is specified, a summary of all metrics is returned. Valid grouping keys: QUEUE | ROUTING_PROFILE | AGENT | CHANNEL | AGENT_HIERARCHY_LEVEL_ONE | AGENT_HIERARCHY_LEVEL_TWO | AGENT_HIERARCHY_LEVEL_THREE | AGENT_HIERARCHY_LEVEL_FOUR | AGENT_HIERARCHY_LEVEL_FIVE
  metrics: list # The metrics to retrieve. Specify the name, groupings, and filters for each metric. The following historical metrics are available. For a description of each metric, see Historical metrics definitions (https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics-definitions.html) in the Amazon Connect Administrator's Guide. AGENT_ADHERENT_TIME This metric is available only in Amazon Web Services Regions where Forecasting, capacity planning, and scheduling (https://docs.aws.amazon.com/connect/latest/adminguide/regions.html#optimization_region) is available. Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AGENT_NON_RESPONSE Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AGENT_OCCUPANCY Unit: Percentage Valid groupings and filters: Routing Profile, Agent, Agent Hierarchy AGENT_SCHEDULE_ADHERENCE This metric is available only in Amazon Web Services Regions where Forecasting, capacity planning, and scheduling (https://docs.aws.amazon.com/connect/latest/adminguide/regions.html#optimization_region) is available. Unit: Percent Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AGENT_SCHEDULED_TIME This metric is available only in Amazon Web Services Regions where Forecasting, capacity planning, and scheduling (https://docs.aws.amazon.com/connect/latest/adminguide/regions.html#optimization_region) is available. Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_ABANDON_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_AFTER_CONTACT_WORK_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_AGENT_CONNECTING_TIME Unit: Seconds Valid metric filter key: INITIATION_METHOD. For now, this metric only supports the following as INITIATION_METHOD: INBOUND | OUTBOUND | CALLBACK | API Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_HANDLE_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_HOLD_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_INTERACTION_AND_HOLD_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_INTERACTION_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile AVG_QUEUE_ANSWER_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile CONTACTS_ABANDONED Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_CREATED Unit: Count Valid metric filter key: INITIATION_METHOD Valid groupings and filters: Queue, Channel, Routing Profile CONTACTS_HANDLED Unit: Count Valid metric filter key: INITIATION_METHOD, DISCONNECT_REASON Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_HOLD_ABANDONS Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_QUEUED Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_TRANSFERRED_OUT Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_TRANSFERRED_OUT_BY_AGENT Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_TRANSFERRED_OUT_FROM_QUEUE Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy MAX_QUEUED_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy SERVICE_LEVEL You can include up to 20 SERVICE_LEVEL metrics in a request. Unit: Percent Valid groupings and filters: Queue, Channel, Routing Profile Threshold: For ThresholdValue, enter any whole number from 1 to 604800 (inclusive), in seconds. For Comparison, you must enter LT (for "Less than"). SUM_CONTACTS_ANSWERED_IN_X Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile Threshold: For ThresholdValue, enter any whole number from 1 to 604800 (inclusive), in seconds. For Comparison, you must enter LT (for "Less than"). SUM_CONTACTS_ABANDONED_IN_X Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile Threshold: For ThresholdValue, enter any whole number from 1 to 604800 (inclusive), in seconds. For Comparison, you must enter LT (for "Less than"). SUM_CONTACTS_DISCONNECTED Valid metric filter key: DISCONNECT_REASON Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile SUM_RETRY_CALLBACK_ATTEMPTS Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile — item shape: {Name?: any, Threshold?: any, MetricFilters?: any}
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
  --max-results-body: int # The maximum number of results to return per page. (body field)
]: any -> record<NextToken: record, MetricResults: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/data" $qp)
  let req_body = {"ResourceArn": $resource_arn, "StartTime": $start_time, "EndTime": $end_time, "Filters": $filters, "Groupings": $groupings, "Metrics": $metrics, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Retrieves the current traffic distribution for a given traffic distribution group.
#
# GET /traffic-distribution/{Id}
# operationId: GetTrafficDistribution
export def "traffic-distribution get" [
  id: string
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
]: nothing -> record<TelephonyConfig: record<Distributions: record>, Id: record, Arn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/traffic-distribution/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the traffic distribution for a given traffic distribution group. For more information about updating a traffic distribution group, see Update telephony traffic distribution across Amazon Web Services Regions (https://docs.aws.amazon.com/connect/latest/adminguide/update-telephony-traffic-distribution.html) in the Amazon Connect Administrator Guide.
#
# PUT /traffic-distribution/{Id}
# operationId: UpdateTrafficDistribution
# --TelephonyConfig shape: {Distributions?: any}
export def "traffic-distribution update" [
  id: string
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
  --telephony-config: record # The distribution of traffic between the instance and its replicas. — shape: {Distributions?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/traffic-distribution/{id}"))
  let req_body = {"TelephonyConfig": $telephony_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all approved origins associated with the instance.
#
# GET /instance/{InstanceId}/approved-origins
# operationId: ListApprovedOrigins
export def "instance-approved-origins list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Origins: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/approved-origins") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. For the specified version of Amazon Lex, returns a paginated list of all the Amazon Lex bots currently associated with the instance. Use this API to returns both Amazon Lex V1 and V2 bots.
#
# GET /instance/{InstanceId}/bots
# operationId: ListBots
export def "instance-bots list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --lex-version: string@lex-version-completer # The version of Amazon Lex or Amazon Lex V2.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<LexBots: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "lexVersion" $lex_version "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/bots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "lexVersion": $lex_version, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Provides information about the flow modules for the specified Amazon Connect instance.
#
# GET /contact-flow-modules-summary/{InstanceId}
# operationId: ListContactFlowModules
export def "contact-flow-modules-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --state: string@state-completer-1 # The state of the flow module.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ContactFlowModulesSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/contact-flow-modules-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "state": $state, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Provides information about the flows for the specified Amazon Connect instance. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html). For more information about flows, see Flows (https://docs.aws.amazon.com/connect/latest/adminguide/concepts-contact-flows.html) in the Amazon Connect Administrator Guide.
#
# GET /contact-flows-summary/{InstanceId}
# operationId: ListContactFlows
export def "contact-flows-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-flow-types: list # The type of flow.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ContactFlowSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "contactFlowTypes" $contact_flow_types "multi") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/contact-flows-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"contactFlowTypes": $contact_flow_types, "nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. For the specified referenceTypes, returns a list of references associated with the contact.
#
# GET /contact/references/{InstanceId}/{ContactId}
# operationId: ListContactReferences
export def "contact-references list" [
  instance_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reference-types: list # The type of reference.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. This is not expected to be set, because the value returned in the previous response is always null.
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ReferenceSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactId' must be non-empty" } }
  let qp = [(serialize-qp "referenceTypes" $reference_types "multi") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_id: (encode-path-segment $contact_id)} | format pattern "/contact/references/{instance_id}/{contact_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"referenceTypes": $reference_types, "nextToken": $next_token, "NextToken": $next_token_2} | compact), body: null}
}

# Lists the default vocabularies for the specified Amazon Connect instance.
#
# POST /default-vocabulary-summary/{InstanceId}
# operationId: ListDefaultVocabularies
export def "default-vocabulary-summary list-vocabularies" [
  instance_id: string
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
  --language-code: string@language-code-completer # The language code of the vocabulary entries. For a list of languages and their corresponding language codes, see What is Amazon Transcribe? (https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-whatis.html)
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
]: any -> record<DefaultVocabularyList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/default-vocabulary-summary/{instance_id}") $qp)
  let req_body = {"LanguageCode": $language_code, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Provides information about the hours of operation for the specified Amazon Connect instance. For more information about hours of operation, see Set the Hours of Operation for a Queue (https://docs.aws.amazon.com/connect/latest/adminguide/set-hours-operation.html) in the Amazon Connect Administrator Guide.
#
# GET /hours-of-operations-summary/{InstanceId}
# operationId: ListHoursOfOperations
export def "hours-of-operations-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<HoursOfOperationSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/hours-of-operations-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all attribute types for the given instance.
#
# GET /instance/{InstanceId}/attributes
# operationId: ListInstanceAttributes
export def "instance-attributes list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Attributes: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/attributes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of storage configs for the identified instance and resource type.
#
# GET /instance/{InstanceId}/storage-configs
# operationId: ListInstanceStorageConfigs
export def "instance-storage-configs list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer # A valid resource type.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<StorageConfigs: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "resourceType" $resource_type "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/storage-configs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"resourceType": $resource_type, "nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all Lambda functions that display in the dropdown options in the relevant flow blocks.
#
# GET /instance/{InstanceId}/lambda-functions
# operationId: ListLambdaFunctions
export def "instance-lambda-functions list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<LambdaFunctions: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/lambda-functions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all the Amazon Lex V1 bots currently associated with the instance. To return both Amazon Lex V1 and V2 bots, use the ListBots (https://docs.aws.amazon.com/connect/latest/APIReference/API_ListBots.html) API.
#
# GET /instance/{InstanceId}/lex-bots
# operationId: ListLexBots
export def "instance-lex-bots list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. If no value is specified, the default is 10.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<LexBots: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/lex-bots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Provides information about the phone numbers for the specified Amazon Connect instance. For more information about phone numbers, see Set Up Phone Numbers for Your Contact Center (https://docs.aws.amazon.com/connect/latest/adminguide/contact-center-phone-number.html) in the Amazon Connect Administrator Guide. The phone number Arn value that is returned from each of the items in the PhoneNumberSummaryList (https://docs.aws.amazon.com/connect/latest/APIReference/API_ListPhoneNumbers.html#connect-ListPhoneNumbers-response-PhoneNumberSummaryList) cannot be used to tag phone number resources. It will fail with a ResourceNotFoundException. Instead, use the ListPhoneNumbersV2 (https://docs.aws.amazon.com/connect/latest/APIReference/API_ListPhoneNumbersV2.html) API. It returns the new phone number ARN that can be used to tag phone number resources.
#
# GET /phone-numbers-summary/{InstanceId}
# operationId: ListPhoneNumbers
export def "phone-numbers-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-number-types: list # The type of phone number.
  --phone-number-country-codes: list # The ISO country code.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<PhoneNumberSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "phoneNumberTypes" $phone_number_types "multi") (serialize-qp "phoneNumberCountryCodes" $phone_number_country_codes "multi") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/phone-numbers-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"phoneNumberTypes": $phone_number_types, "phoneNumberCountryCodes": $phone_number_country_codes, "nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Lists phone numbers claimed to your Amazon Connect instance or traffic distribution group. If the provided TargetArn is a traffic distribution group, you can call this API in both Amazon Web Services Regions associated with traffic distribution group. For more information about phone numbers, see Set Up Phone Numbers for Your Contact Center (https://docs.aws.amazon.com/connect/latest/adminguide/contact-center-phone-number.html) in the Amazon Connect Administrator Guide.
#
# POST /phone-number/list
# operationId: ListPhoneNumbersV2
export def "phone-number-list list" [
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
  --target-arn: string # The Amazon Resource Name (ARN) for Amazon Connect instances or traffic distribution groups that phone numbers are claimed to. If TargetArn input is not provided, this API lists numbers claimed to all the Amazon Connect instances belonging to your account in the same Amazon Web Services Region as the request.
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
  --phone-number-country-codes: list<string> # The ISO country code.
  --phone-number-types: list<string> # The type of phone number.
  --phone-number-prefix: string # The prefix of the phone number. If provided, it must contain + as part of the country code.
]: any -> record<NextToken: record, ListPhoneNumbersSummaryList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone-number/list" $qp)
  let req_body = {"TargetArn": $target_arn, "MaxResults": $max_results_body, "NextToken": $next_token_body, "PhoneNumberCountryCodes": $phone_number_country_codes, "PhoneNumberTypes": $phone_number_types, "PhoneNumberPrefix": $phone_number_prefix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Provides information about the prompts for the specified Amazon Connect instance.
#
# GET /prompts-summary/{InstanceId}
# operationId: ListPrompts
export def "prompts-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<PromptSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/prompts-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Lists the quick connects associated with a queue.
#
# GET /queues/{InstanceId}/{QueueId}/quick-connects
# operationId: ListQueueQuickConnects
export def "queues-quick-connects list" [
  instance_id: string
  queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, QuickConnectSummaryList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'QueueId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/queues/{instance_id}/{queue_id}/quick-connects") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Provides information about the queues for the specified Amazon Connect instance. If you do not specify a QueueTypes parameter, both standard and agent queues are returned. This might cause an unexpected truncation of results if you have more than 1000 agents and you limit the number of results of the API call in code. For more information about queues, see Queues: Standard and Agent (https://docs.aws.amazon.com/connect/latest/adminguide/concepts-queues-standard-and-agent.html) in the Amazon Connect Administrator Guide.
#
# GET /queues-summary/{InstanceId}
# operationId: ListQueues
export def "queues-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --queue-types: list # The type of queue.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<QueueSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "queueTypes" $queue_types "multi") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/queues-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"queueTypes": $queue_types, "nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Lists the queues associated with a routing profile.
#
# GET /routing-profiles/{InstanceId}/{RoutingProfileId}/queues
# operationId: ListRoutingProfileQueues
export def "routing-profiles-queues list" [
  instance_id: string
  routing_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, RoutingProfileQueueConfigSummaryList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($routing_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'RoutingProfileId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), routing_profile_id: (encode-path-segment $routing_profile_id)} | format pattern "/routing-profiles/{instance_id}/{routing_profile_id}/queues") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Updates the properties associated with a set of queues for a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/queues
# operationId: UpdateRoutingProfileQueues
# --QueueConfigs item shape: {QueueReference: any, Priority: any, Delay: any}
export def "routing-profiles-queues update" [
  instance_id: string
  routing_profile_id: string
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
  queue_configs: list # The queues to be updated for this routing profile. Queues must first be associated to the routing profile. You can do this using AssociateRoutingProfileQueues. — item shape: {QueueReference: any, Priority: any, Delay: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($routing_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'RoutingProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), routing_profile_id: (encode-path-segment $routing_profile_id)} | format pattern "/routing-profiles/{instance_id}/{routing_profile_id}/queues"))
  let req_body = {"QueueConfigs": $queue_configs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Provides summary information about the routing profiles for the specified Amazon Connect instance. For more information about routing profiles, see Routing Profiles (https://docs.aws.amazon.com/connect/latest/adminguide/concepts-routing.html) and Create a Routing Profile (https://docs.aws.amazon.com/connect/latest/adminguide/routing-profiles.html) in the Amazon Connect Administrator Guide.
#
# GET /routing-profiles-summary/{InstanceId}
# operationId: ListRoutingProfiles
export def "routing-profiles-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RoutingProfileSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/routing-profiles-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all security keys associated with the instance.
#
# GET /instance/{InstanceId}/security-keys
# operationId: ListSecurityKeys
export def "instance-security-keys list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SecurityKeys: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/security-keys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# This API is in preview release for Amazon Connect and is subject to change. Lists the permissions granted to a security profile.
#
# GET /security-profiles-permissions/{InstanceId}/{SecurityProfileId}
# operationId: ListSecurityProfilePermissions
export def "security-profiles-permissions list" [
  instance_id: string
  security_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Permissions: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($security_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'SecurityProfileId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), security_profile_id: (encode-path-segment $security_profile_id)} | format pattern "/security-profiles-permissions/{instance_id}/{security_profile_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Provides summary information about the security profiles for the specified Amazon Connect instance. For more information about security profiles, see Security Profiles (https://docs.aws.amazon.com/connect/latest/adminguide/connect-security-profiles.html) in the Amazon Connect Administrator Guide.
#
# GET /security-profiles-summary/{InstanceId}
# operationId: ListSecurityProfiles
export def "security-profiles-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SecurityProfileSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/security-profiles-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Lists the tags for the specified resource. For sample policies that use tags, see Amazon Connect Identity-Based Policy Examples (https://docs.aws.amazon.com/connect/latest/adminguide/security_iam_id-based-policy-examples.html) in the Amazon Connect Administrator Guide.
#
# GET /tags/{resourceArn}
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  resource_arn: string
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
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds the specified tags to the specified resource. Some of the supported resource types are agents, routing profiles, queues, quick connects, contact flows, agent statuses, hours of operation, phone numbers, security profiles, and task templates. For a complete list, see Tagging resources in Amazon Connect (https://docs.aws.amazon.com/connect/latest/adminguide/tagging.html). For sample policies that use tags, see Amazon Connect Identity-Based Policy Examples (https://docs.aws.amazon.com/connect/latest/adminguide/security_iam_id-based-policy-examples.html) in the Amazon Connect Administrator Guide.
#
# POST /tags/{resourceArn}
# operationId: TagResource
export def "tags tag-resource" [
  resource_arn: string
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
  tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists traffic distribution groups.
#
# GET /traffic-distribution-groups
# operationId: ListTrafficDistributionGroups
export def "traffic-distribution-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --instance-id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, TrafficDistributionGroupSummaryList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "instanceId" $instance_id "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/traffic-distribution-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "instanceId": $instance_id, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Provides summary information about the hierarchy groups for the specified Amazon Connect instance. For more information about agent hierarchies, see Set Up Agent Hierarchies (https://docs.aws.amazon.com/connect/latest/adminguide/agent-hierarchy.html) in the Amazon Connect Administrator Guide.
#
# GET /user-hierarchy-groups-summary/{InstanceId}
# operationId: ListUserHierarchyGroups
export def "user-hierarchy-groups-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UserHierarchyGroupSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/user-hierarchy-groups-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Provides summary information about the users for the specified Amazon Connect instance.
#
# GET /users-summary/{InstanceId}
# operationId: ListUsers
export def "users-summary list" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UserSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/users-summary/{instance_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "maxResults": $max_results, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Initiates silent monitoring of a contact. The Contact Control Panel (CCP) of the user specified by userId will be set to silent monitoring mode on the contact.
#
# POST /contact/monitor
# operationId: MonitorContact
export def "contact-monitor create" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instanceId in the ARN of the instance.
  contact_id: string # The identifier of the contact.
  user_id: string # The identifier of the user account.
  --allowed-monitor-capabilities: list<string> # Specify which monitoring actions the user is allowed to take. For example, whether the user is allowed to escalate from silent monitoring to barge.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<ContactId: record, ContactArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/monitor")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "UserId": $user_id, "AllowedMonitorCapabilities": $allowed_monitor_capabilities, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Changes the current status of a user or agent in Amazon Connect. If the agent is currently handling a contact, this sets the agent's next status. For more information, see Agent status (https://docs.aws.amazon.com/connect/latest/adminguide/metrics-agent-status.html) and Set your next status (https://docs.aws.amazon.com/connect/latest/adminguide/set-next-status.html) in the Amazon Connect Administrator Guide.
#
# PUT /users/{InstanceId}/{UserId}/status
# operationId: PutUserStatus
export def "users-status update" [
  instance_id: string
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
  agent_status_id: string # The identifier of the agent status.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), user_id: (encode-path-segment $user_id)} | format pattern "/users/{instance_id}/{user_id}/status"))
  let req_body = {"AgentStatusId": $agent_status_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replicates an Amazon Connect instance in the specified Amazon Web Services Region. For more information about replicating an Amazon Connect instance, see Create a replica of your existing Amazon Connect instance (https://docs.aws.amazon.com/connect/latest/adminguide/create-replica-connect-instance.html) in the Amazon Connect Administrator Guide.
#
# POST /instance/{InstanceId}/replicate
# operationId: ReplicateInstance
export def "instance-replicate create" [
  instance_id: string
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
  replica_region: string # The Amazon Web Services Region where to replicate the Amazon Connect instance.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  replica_alias: string # The alias for the replicated instance. The ReplicaAlias must be unique. (format: password)
]: any -> record<Id: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/instance/{instance_id}/replicate"))
  let req_body = {"ReplicaRegion": $replica_region, "ClientToken": $client_token, "ReplicaAlias": $replica_alias} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# When a contact is being recorded, and the recording has been suspended using SuspendContactRecording, this API resumes recording the call. Only voice recordings are supported at this time.
#
# POST /contact/resume-recording
# operationId: ResumeContactRecording
export def "contact-resume-recording create" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/resume-recording")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "InitialContactId": $initial_contact_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Searches for available phone numbers that you can claim to your Amazon Connect instance or traffic distribution group. If the provided TargetArn is a traffic distribution group, you can call this API in both Amazon Web Services Regions associated with the traffic distribution group.
#
# POST /phone-number/search-available
# operationId: SearchAvailablePhoneNumbers
export def "phone-number-search-available list" [
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
  target_arn: string # The Amazon Resource Name (ARN) for Amazon Connect instances or traffic distribution groups that phone numbers are claimed to.
  phone_number_country_code: string@phone-number-country-code-completer # The ISO country code.
  phone_number_type: string@phone-number-type-completer # The type of phone number.
  --phone-number-prefix: string # The prefix of the phone number. If provided, it must contain + as part of the country code.
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
]: any -> record<NextToken: record, AvailableNumbersList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone-number/search-available" $qp)
  let req_body = {"TargetArn": $target_arn, "PhoneNumberCountryCode": $phone_number_country_code, "PhoneNumberType": $phone_number_type, "PhoneNumberPrefix": $phone_number_prefix, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Searches queues in an Amazon Connect instance, with optional filtering.
#
# POST /search-queues
# operationId: SearchQueues
# --SearchFilter shape: {TagFilter?: record}
# --SearchCriteria shape: {OrConditions?: any, AndConditions?: any, StringCondition?: record, QueueTypeCondition?: any}
export def "search-queues list" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --search-filter: record # Filters to be applied to search results. — shape: {TagFilter?: record}
  --search-criteria: record # The search criteria to be used to return queues. The name and description fields support "contains" queries with a minimum of 2 characters and a maximum of 25 characters. Any queries with character lengths outside of this range will throw invalid results. — shape: {OrConditions?: any, AndConditions?: any, StringCondition?: record, QueueTypeCondition?: any}
]: any -> record<Queues: record, NextToken: record, ApproximateTotalCount: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-queues" $qp)
  let req_body = {"InstanceId": $instance_id, "NextToken": $next_token_body, "MaxResults": $max_results_body, "SearchFilter": $search_filter, "SearchCriteria": $search_criteria} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Searches routing profiles in an Amazon Connect instance, with optional filtering.
#
# POST /search-routing-profiles
# operationId: SearchRoutingProfiles
# --SearchFilter shape: {TagFilter?: record}
# --SearchCriteria shape: {OrConditions?: any, AndConditions?: any, StringCondition?: record}
export def "search-routing-profiles list" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --search-filter: record # Filters to be applied to search results. — shape: {TagFilter?: record}
  --search-criteria: record # The search criteria to be used to return routing profiles. The name and description fields support "contains" queries with a minimum of 2 characters and a maximum of 25 characters. Any queries with character lengths outside of this range will throw invalid results. — shape: {OrConditions?: any, AndConditions?: any, StringCondition?: record}
]: any -> record<RoutingProfiles: record, NextToken: record, ApproximateTotalCount: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-routing-profiles" $qp)
  let req_body = {"InstanceId": $instance_id, "NextToken": $next_token_body, "MaxResults": $max_results_body, "SearchFilter": $search_filter, "SearchCriteria": $search_criteria} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Searches security profiles in an Amazon Connect instance, with optional filtering.
#
# POST /search-security-profiles
# operationId: SearchSecurityProfiles
# --SearchCriteria shape: {OrConditions?: any, AndConditions?: any, StringCondition?: record}
# --SearchFilter shape: {TagFilter?: record}
export def "search-security-profiles list" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --search-criteria: record # The search criteria to be used to return security profiles. The name field support "contains" queries with a minimum of 2 characters and maximum of 25 characters. Any queries with character lengths outside of this range will throw invalid results. — shape: {OrConditions?: any, AndConditions?: any, StringCondition?: record}
  --search-filter: record # Filters to be applied to search results. — shape: {TagFilter?: record}
]: any -> record<SecurityProfiles: record, NextToken: record, ApproximateTotalCount: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-security-profiles" $qp)
  let req_body = {"InstanceId": $instance_id, "NextToken": $next_token_body, "MaxResults": $max_results_body, "SearchCriteria": $search_criteria, "SearchFilter": $search_filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Searches users in an Amazon Connect instance, with optional filtering. AfterContactWorkTimeLimit is returned in milliseconds.
#
# POST /search-users
# operationId: SearchUsers
# --SearchFilter shape: {TagFilter?: record}
# --SearchCriteria shape: {OrConditions?: any, AndConditions?: any, StringCondition?: any, HierarchyGroupCondition?: any}
export def "search-users list" [
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
  --instance-id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --search-filter: record # Filters to be applied to search results. — shape: {TagFilter?: record}
  --search-criteria: record # The search criteria to be used to return users. The name and description fields support "contains" queries with a minimum of 2 characters and a maximum of 25 characters. Any queries with character lengths outside of this range will throw invalid results. — shape: {OrConditions?: any, AndConditions?: any, StringCondition?: any, HierarchyGroupCondition?: any}
]: any -> record<Users: record, NextToken: record, ApproximateTotalCount: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-users" $qp)
  let req_body = {"InstanceId": $instance_id, "NextToken": $next_token_body, "MaxResults": $max_results_body, "SearchFilter": $search_filter, "SearchCriteria": $search_criteria} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Searches for vocabularies within a specific Amazon Connect instance using State, NameStartsWith, and LanguageCode.
#
# POST /vocabulary-summary/{InstanceId}
# operationId: SearchVocabularies
export def "vocabulary-summary list-vocabularies" [
  instance_id: string
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
  --max-results-body: int # The maximum number of results to return per page. (body field)
  --next-token-body: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (body field)
  --state: string@state-completer-2 # The current state of the custom vocabulary.
  --name-starts-with: string # The starting pattern of the name of the vocabulary.
  --language-code: string@language-code-completer # The language code of the vocabulary entries. For a list of languages and their corresponding language codes, see What is Amazon Transcribe? (https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-whatis.html)
]: any -> record<VocabularySummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id)} | format pattern "/vocabulary-summary/{instance_id}") $qp)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body, "State": $state, "NameStartsWith": $name_starts_with, "LanguageCode": $language_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Initiates a flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the CreateParticipantConnection (https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html) API in the Amazon Connect Participant Service. When a new chat contact is successfully created, clients must subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking CreateParticipantConnection (https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html) with WEBSOCKET and CONNECTION_CREDENTIALS. A 429 error occurs in the following situations: API rate limit is exceeded. API TPS throttling returns a TooManyRequests exception. The quota for concurrent active chats (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html) is exceeded. Active chat throttling returns a LimitExceededException. If you use the ChatDurationInMinutes parameter and receive a 400 error, your account may not support the ability to configure custom chat durations. For more information, contact Amazon Web Services Support. For more information about chat, see Chat (https://docs.aws.amazon.com/connect/latest/adminguide/chat.html) in the Amazon Connect Administrator Guide.
#
# PUT /contact/chat
# operationId: StartChatContact
# --ParticipantDetails shape: {DisplayName?: any}
# --InitialMessage shape: {ContentType?: any, Content?: any}
# --PersistentChat shape: {RehydrationType?: any, SourceContactId?: any}
export def "contact-chat start" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_flow_id: string # The identifier of the flow for initiating the chat. To see the ContactFlowId in the Amazon Connect console user interface, on the navigation menu go to Routing, Contact Flows. Choose the flow. On the flow page, under the name of the flow, choose Show additional flow information. The ContactFlowId is the last part of the ARN, shown here in bold: arn:aws:connect:us-west-2:xxxxxxxxxxxx:instance/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/contact-flow/846ec553-a005-41c0-8341-xxxxxxxxxxxx
  --attributes: record # A custom key-value pair using an attribute map. The attributes are standard Amazon Connect attributes. They can be accessed in flows just like any other contact attributes. There can be up to 32,768 UTF-8 bytes across all key-value pairs per contact. Attribute keys can include only alphanumeric, dash, and underscore characters.
  participant_details: record # The customer's details. — shape: {DisplayName?: any}
  --initial-message: record # A chat message. — shape: {ContentType?: any, Content?: any}
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  --chat-duration-in-minutes: int # The total duration of the newly started chat session. If not specified, the chat session duration defaults to 25 hour. The minimum configurable time is 60 minutes. The maximum configurable time is 10,080 minutes (7 days).
  --supported-messaging-content-types: list<string> # The supported chat message content types. Supported types are text/plain, text/markdown, application/json, application/vnd.amazonaws.connect.message.interactive, and application/vnd.amazonaws.connect.message.interactive.response. Content types must always contain text/plain. You can then put any other supported type in the list. For example, all the following lists are valid because they contain text/plain: [text/plain, text/markdown, application/json], [text/markdown, text/plain], [text/plain, application/json, application/vnd.amazonaws.connect.message.interactive.response]. The type application/vnd.amazonaws.connect.message.interactive is required to use the Show view (https://docs.aws.amazon.com/connect/latest/adminguide/show-view-block.html) flow block.
  --persistent-chat: record # Enable persistent chats. For more information about enabling persistent chat, and for example use cases and how to configure for them, see Enable persistent chat (https://docs.aws.amazon.com/connect/latest/adminguide/chat-persistence.html). — shape: {RehydrationType?: any, SourceContactId?: any}
  --related-contact-id: string # The unique identifier for an Amazon Connect contact. This identifier is related to the chat starting. You cannot provide data for both RelatedContactId and PersistentChat.
]: any -> record<ContactId: record, ParticipantId: record, ParticipantToken: record, ContinuedFromContactId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/chat")
  let req_body = {"InstanceId": $instance_id, "ContactFlowId": $contact_flow_id, "Attributes": $attributes, "ParticipantDetails": $participant_details, "InitialMessage": $initial_message, "ClientToken": $client_token, "ChatDurationInMinutes": $chat_duration_in_minutes, "SupportedMessagingContentTypes": $supported_messaging_content_types, "PersistentChat": $persistent_chat, "RelatedContactId": $related_contact_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Starts recording the contact: If the API is called before the agent joins the call, recording starts when the agent joins the call. If the API is called after the agent joins the call, recording starts at the time of the API call. StartContactRecording is a one-time action. For example, if you use StopContactRecording to stop recording an ongoing call, you can't use StartContactRecording to restart it. For scenarios where the recording has started and you want to suspend and resume it, such as when collecting sensitive information (for example, a credit card number), use SuspendContactRecording and ResumeContactRecording. You can use this API to override the recording behavior configured in the Set recording behavior (https://docs.aws.amazon.com/connect/latest/adminguide/set-recording-behavior.html) block. Only voice recordings are supported at this time.
#
# POST /contact/start-recording
# operationId: StartContactRecording
# --VoiceRecordingConfiguration shape: {VoiceRecordingTrack?: any}
export def "contact-start-recording start" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
  voice_recording_configuration: record # Contains information about the recording configuration settings. — shape: {VoiceRecordingTrack?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/start-recording")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "InitialContactId": $initial_contact_id, "VoiceRecordingConfiguration": $voice_recording_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Initiates real-time message streaming for a new chat contact. For more information about message streaming, see Enable real-time chat message streaming (https://docs.aws.amazon.com/connect/latest/adminguide/chat-message-streaming.html) in the Amazon Connect Administrator Guide.
#
# POST /contact/start-streaming
# operationId: StartContactStreaming
# --ChatStreamingConfiguration shape: {StreamingEndpointArn?: any}
export def "contact-start-streaming start" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
  chat_streaming_configuration: record # The streaming configuration, such as the Amazon SNS streaming endpoint. — shape: {StreamingEndpointArn?: any}
  client_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<StreamingId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/start-streaming")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "ChatStreamingConfiguration": $chat_streaming_configuration, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Places an outbound call to a contact, and then initiates the flow. It performs the actions in the flow that's specified (in ContactFlowId). Agents do not initiate the outbound API, which means that they do not dial the contact. If the flow places an outbound call to a contact, and then puts the contact in queue, the call is then routed to the agent, like any other inbound case. There is a 60-second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails. UK numbers with a 447 prefix are not allowed by default. Before you can dial these UK mobile numbers, you must submit a service quota increase request. For more information, see Amazon Connect Service Quotas (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html) in the Amazon Connect Administrator Guide. Campaign calls are not allowed by default. Before you can make a call with TrafficType = CAMPAIGN, you must submit a service quota increase request to the quota Amazon Connect campaigns (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html#outbound-communications-quotas).
#
# PUT /contact/outbound-voice
# operationId: StartOutboundVoiceContact
# --AnswerMachineDetectionConfig shape: {EnableAnswerMachineDetection?: any, AwaitAnswerMachinePrompt?: any}
export def "contact-outbound-voice start" [
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
  destination_phone_number: string # The phone number of the customer, in E.164 format.
  contact_flow_id: string # The identifier of the flow for the outbound call. To see the ContactFlowId in the Amazon Connect console user interface, on the navigation menu go to Routing, Contact Flows. Choose the flow. On the flow page, under the name of the flow, choose Show additional flow information. The ContactFlowId is the last part of the ARN, shown here in bold: arn:aws:connect:us-west-2:xxxxxxxxxxxx:instance/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/contact-flow/846ec553-a005-41c0-8341-xxxxxxxxxxxx
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). The token is valid for 7 days after creation. If a contact is already started, the contact ID is returned.
  --source-phone-number: string # The phone number associated with the Amazon Connect instance, in E.164 format. If you do not specify a source phone number, you must specify a queue.
  --queue-id: string # The queue for the call. If you specify a queue, the phone displayed for caller ID is the phone number specified in the queue. If you do not specify a queue, the queue defined in the flow is used. If you do not specify a queue, you must specify a source phone number.
  --attributes: record # A custom key-value pair using an attribute map. The attributes are standard Amazon Connect attributes, and can be accessed in flows just like any other contact attributes. There can be up to 32,768 UTF-8 bytes across all key-value pairs per contact. Attribute keys can include only alphanumeric, dash, and underscore characters.
  --answer-machine-detection-config: record # Configuration of the answering machine detection. — shape: {EnableAnswerMachineDetection?: any, AwaitAnswerMachinePrompt?: any}
  --campaign-id: string # The campaign identifier of the outbound communication.
  --traffic-type: string@traffic-type-completer # Denotes the class of traffic. Calls with different traffic types are handled differently by Amazon Connect. The default value is GENERAL. Use CAMPAIGN if EnableAnswerMachineDetection is set to true. For all other cases, use GENERAL.
]: any -> record<ContactId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/outbound-voice")
  let req_body = {"DestinationPhoneNumber": $destination_phone_number, "ContactFlowId": $contact_flow_id, "InstanceId": $instance_id, "ClientToken": $client_token, "SourcePhoneNumber": $source_phone_number, "QueueId": $queue_id, "Attributes": $attributes, "AnswerMachineDetectionConfig": $answer_machine_detection_config, "CampaignId": $campaign_id, "TrafficType": $traffic_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Initiates a flow to start a new task.
#
# PUT /contact/task
# operationId: StartTaskContact
export def "contact-task start" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --previous-contact-id: string # The identifier of the previous chat, voice, or task contact.
  --contact-flow-id: string # The identifier of the flow for initiating the tasks. To see the ContactFlowId in the Amazon Connect console user interface, on the navigation menu go to Routing, Contact Flows. Choose the flow. On the flow page, under the name of the flow, choose Show additional flow information. The ContactFlowId is the last part of the ARN, shown here in bold: arn:aws:connect:us-west-2:xxxxxxxxxxxx:instance/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/contact-flow/846ec553-a005-41c0-8341-xxxxxxxxxxxx
  --attributes: record # A custom key-value pair using an attribute map. The attributes are standard Amazon Connect attributes, and can be accessed in flows just like any other contact attributes. There can be up to 32,768 UTF-8 bytes across all key-value pairs per contact. Attribute keys can include only alphanumeric, dash, and underscore characters.
  name: string # The name of a task that is shown to an agent in the Contact Control Panel (CCP).
  --references: record # A formatted URL that is shown to an agent in the Contact Control Panel (CCP).
  --description: string # A description of the task that is shown to an agent in the Contact Control Panel (CCP).
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  --scheduled-time: string # The timestamp, in Unix Epoch seconds format, at which to start running the inbound flow. The scheduled time cannot be in the past. It must be within up to 6 days in future. (format: date-time)
  --task-template-id: string # A unique identifier for the task template.
  --quick-connect-id: string # The identifier for the quick connect.
  --related-contact-id: string # The contactId that is related (https://docs.aws.amazon.com/connect/latest/adminguide/tasks.html#linked-tasks) to this contact.
]: any -> record<ContactId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/task")
  let req_body = {"InstanceId": $instance_id, "PreviousContactId": $previous_contact_id, "ContactFlowId": $contact_flow_id, "Attributes": $attributes, "Name": $name, "References": $references, "Description": $description, "ClientToken": $client_token, "ScheduledTime": $scheduled_time, "TaskTemplateId": $task_template_id, "QuickConnectId": $quick_connect_id, "RelatedContactId": $related_contact_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Ends the specified contact. This call does not work for the following initiation methods: DISCONNECT TRANSFER QUEUE_TRANSFER
#
# POST /contact/stop
# operationId: StopContact
export def "contact-stop stop" [
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
  contact_id: string # The ID of the contact.
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/stop")
  let req_body = {"ContactId": $contact_id, "InstanceId": $instance_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Stops recording a call when a contact is being recorded. StopContactRecording is a one-time action. If you use StopContactRecording to stop recording an ongoing call, you can't use StartContactRecording to restart it. For scenarios where the recording has started and you want to suspend it for sensitive information (for example, to collect a credit card number), and then restart it, use SuspendContactRecording and ResumeContactRecording. Only voice recordings are supported at this time.
#
# POST /contact/stop-recording
# operationId: StopContactRecording
export def "contact-stop-recording stop" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/stop-recording")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "InitialContactId": $initial_contact_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Ends message streaming on a specified contact. To restart message streaming on that contact, call the StartContactStreaming (https://docs.aws.amazon.com/connect/latest/APIReference/API_StartContactStreaming.html) API.
#
# POST /contact/stop-streaming
# operationId: StopContactStreaming
export def "contact-stop-streaming stop" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact. This is the identifier of the contact that is associated with the first interaction with the contact center.
  streaming_id: string # The identifier of the streaming configuration enabled.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/stop-streaming")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "StreamingId": $streaming_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# When a contact is being recorded, this API suspends recording the call. For example, you might suspend the call recording while collecting sensitive information, such as a credit card number. Then use ResumeContactRecording to restart recording. The period of time that the recording is suspended is filled with silence in the final recording. Only voice recordings are supported at this time.
#
# POST /contact/suspend-recording
# operationId: SuspendContactRecording
export def "contact-suspend-recording create" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/suspend-recording")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "InitialContactId": $initial_contact_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Transfers contacts from one agent or queue to another agent or queue at any point after a contact is created. You can transfer a contact to another queue by providing the flow which orchestrates the contact to the destination queue. This gives you more control over contact handling and helps you adhere to the service level agreement (SLA) guaranteed to your customers. Note the following requirements: Transfer is supported for only TASK contacts. Do not use both QueueId and UserId in the same call. The following flow types are supported: Inbound flow, Transfer to agent flow, and Transfer to queue flow. The TransferContact API can be called only on active contacts. A contact cannot be transferred more than 11 times.
#
# POST /contact/transfer
# operationId: TransferContact
export def "contact-transfer create" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact in this instance of Amazon Connect.
  --queue-id: string # The identifier for the queue.
  --user-id: string # The identifier for the user.
  contact_flow_id: string # The identifier of the flow.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> record<ContactId: record, ContactArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/transfer")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "QueueId": $queue_id, "UserId": $user_id, "ContactFlowId": $contact_flow_id, "ClientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes the specified tags from the specified resource.
#
# DELETE /tags/{resourceArn}
# operationId: UntagResource
export def "tags untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The tag keys.
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}

# Creates or updates user-defined contact attributes associated with the specified contact. You can create or update user-defined attributes for both ongoing and completed contacts. For example, while the call is active, you can update the customer's name or the reason the customer called. You can add notes about steps that the agent took during the call that display to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or to identify abusive callers. Contact attributes are available in Amazon Connect for 24 months, and are then deleted. For information about contact record retention and the maximum size of the contact record attributes section, see Feature specifications (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html#feature-limits) in the Amazon Connect Administrator Guide.
#
# POST /contact/attributes
# operationId: UpdateContactAttributes
export def "contact-attributes update" [
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
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  attributes: record # The Amazon Connect attributes. These attributes can be accessed in flows just like any other contact attributes. You can have up to 32,768 UTF-8 bytes across all attributes for a contact. Attribute keys can include only alphanumeric, dash, and underscore characters.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/attributes")
  let req_body = {"InitialContactId": $initial_contact_id, "InstanceId": $instance_id, "Attributes": $attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the specified flow. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html).
#
# POST /contact-flows/{InstanceId}/{ContactFlowId}/content
# operationId: UpdateContactFlowContent
export def "contact-flows-content update" [
  instance_id: string
  contact_flow_id: string
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
  content: string # The JSON string that represents flow's content. For an example, see Example contact flow in Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language-example.html).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_flow_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactFlowId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_flow_id: (encode-path-segment $contact_flow_id)} | format pattern "/contact-flows/{instance_id}/{contact_flow_id}/content"))
  let req_body = {"Content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates metadata about specified flow.
#
# POST /contact-flows/{InstanceId}/{ContactFlowId}/metadata
# operationId: UpdateContactFlowMetadata
export def "contact-flows-metadata update" [
  instance_id: string
  contact_flow_id: string
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
  --name: string # The name of the flow.
  --description: string # The description of the flow.
  --contact-flow-state: string@contact-flow-state-completer # The state of flow.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_flow_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactFlowId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_flow_id: (encode-path-segment $contact_flow_id)} | format pattern "/contact-flows/{instance_id}/{contact_flow_id}/metadata"))
  let req_body = {"Name": $name, "Description": $description, "ContactFlowState": $contact_flow_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates specified flow module for the specified Amazon Connect instance.
#
# POST /contact-flow-modules/{InstanceId}/{ContactFlowModuleId}/content
# operationId: UpdateContactFlowModuleContent
export def "contact-flow-modules-content update" [
  instance_id: string
  contact_flow_module_id: string
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
  content: string # The content of the flow module.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_flow_module_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactFlowModuleId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_flow_module_id: (encode-path-segment $contact_flow_module_id)} | format pattern "/contact-flow-modules/{instance_id}/{contact_flow_module_id}/content"))
  let req_body = {"Content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates metadata about specified flow module.
#
# POST /contact-flow-modules/{InstanceId}/{ContactFlowModuleId}/metadata
# operationId: UpdateContactFlowModuleMetadata
export def "contact-flow-modules-metadata update" [
  instance_id: string
  contact_flow_module_id: string
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
  --name: string # The name of the flow module.
  --description: string # The description of the flow module.
  --state: string@state-completer-1 # The state of flow module.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_flow_module_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactFlowModuleId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_flow_module_id: (encode-path-segment $contact_flow_module_id)} | format pattern "/contact-flow-modules/{instance_id}/{contact_flow_module_id}/metadata"))
  let req_body = {"Name": $name, "Description": $description, "State": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The name of the flow. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html).
#
# POST /contact-flows/{InstanceId}/{ContactFlowId}/name
# operationId: UpdateContactFlowName
export def "contact-flows-name update" [
  instance_id: string
  contact_flow_id: string
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
  --name: string # The name of the flow.
  --description: string # The description of the flow.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_flow_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactFlowId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_flow_id: (encode-path-segment $contact_flow_id)} | format pattern "/contact-flows/{instance_id}/{contact_flow_id}/name"))
  let req_body = {"Name": $name, "Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the scheduled time of a task contact that is already scheduled.
#
# POST /contact/schedule
# operationId: UpdateContactSchedule
export def "contact-schedule update" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  scheduled_time: string # The timestamp, in Unix Epoch seconds format, at which to start running the inbound flow. The scheduled time cannot be in the past. It must be within up to 6 days in future. (format: date-time)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact/schedule")
  let req_body = {"InstanceId": $instance_id, "ContactId": $contact_id, "ScheduledTime": $scheduled_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates timeouts for when human chat participants are to be considered idle, and when agents are automatically disconnected from a chat due to idleness. You can set four timers: Customer idle timeout Customer auto-disconnect timeout Agent idle timeout Agent auto-disconnect timeout For more information about how chat timeouts work, see Set up chat timeouts for human participants (https://docs.aws.amazon.com/connect/latest/adminguide/setup-chat-timeouts.html).
#
# PUT /contact/participant-role-config/{InstanceId}/{ContactId}
# operationId: UpdateParticipantRoleConfig
# --ChannelConfiguration shape: {Chat?: any}
export def "contact-participant-role-config update" [
  instance_id: string
  contact_id: string
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
  channel_configuration: record # Configuration information for the chat participant role. — shape: {Chat?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'ContactId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), contact_id: (encode-path-segment $contact_id)} | format pattern "/contact/participant-role-config/{instance_id}/{contact_id}"))
  let req_body = {"ChannelConfiguration": $channel_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the hours of operation for the specified queue.
#
# POST /queues/{InstanceId}/{QueueId}/hours-of-operation
# operationId: UpdateQueueHoursOfOperation
export def "queues-hours-of-operation update" [
  instance_id: string
  queue_id: string
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
  hours_of_operation_id: string # The identifier for the hours of operation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'QueueId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/queues/{instance_id}/{queue_id}/hours-of-operation"))
  let req_body = {"HoursOfOperationId": $hours_of_operation_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the maximum number of contacts allowed in a queue before it is considered full.
#
# POST /queues/{InstanceId}/{QueueId}/max-contacts
# operationId: UpdateQueueMaxContacts
export def "queues-max-contacts update" [
  instance_id: string
  queue_id: string
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
  --max-contacts: int # The maximum number of contacts that can be in the queue before it is considered full.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'QueueId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/queues/{instance_id}/{queue_id}/max-contacts"))
  let req_body = {"MaxContacts": $max_contacts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the name and description of a queue. At least Name or Description must be provided.
#
# POST /queues/{InstanceId}/{QueueId}/name
# operationId: UpdateQueueName
export def "queues-name update" [
  instance_id: string
  queue_id: string
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
  --name: string # The name of the queue.
  --description: string # The description of the queue.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'QueueId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/queues/{instance_id}/{queue_id}/name"))
  let req_body = {"Name": $name, "Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the outbound caller ID name, number, and outbound whisper flow for a specified queue. If the number being used in the input is claimed to a traffic distribution group, and you are calling this API using an instance in the Amazon Web Services Region where the traffic distribution group was created, you can use either a full phone number ARN or UUID value for the OutboundCallerIdNumberId value of the OutboundCallerConfig (https://docs.aws.amazon.com/connect/latest/APIReference/API_OutboundCallerConfig) request body parameter. However, if the number is claimed to a traffic distribution group and you are calling this API using an instance in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# POST /queues/{InstanceId}/{QueueId}/outbound-caller-config
# operationId: UpdateQueueOutboundCallerConfig
# --OutboundCallerConfig shape: {OutboundCallerIdName?: any, OutboundCallerIdNumberId?: any, OutboundFlowId?: any}
export def "queues-outbound-caller-config update" [
  instance_id: string
  queue_id: string
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
  outbound_caller_config: record # The outbound caller ID name, number, and outbound whisper flow. — shape: {OutboundCallerIdName?: any, OutboundCallerIdNumberId?: any, OutboundFlowId?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'QueueId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/queues/{instance_id}/{queue_id}/outbound-caller-config"))
  let req_body = {"OutboundCallerConfig": $outbound_caller_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the status of the queue.
#
# POST /queues/{InstanceId}/{QueueId}/status
# operationId: UpdateQueueStatus
export def "queues-status update" [
  instance_id: string
  queue_id: string
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
  status: string@status-completer-1 # The status of the queue.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'QueueId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/queues/{instance_id}/{queue_id}/status"))
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the configuration settings for the specified quick connect.
#
# POST /quick-connects/{InstanceId}/{QuickConnectId}/config
# operationId: UpdateQuickConnectConfig
# --QuickConnectConfig shape: {QuickConnectType?: any, UserConfig?: any, QueueConfig?: any, PhoneConfig?: any}
export def "quick-connects-config update" [
  instance_id: string
  quick_connect_id: string
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
  quick_connect_config: record # Contains configuration settings for a quick connect. — shape: {QuickConnectType?: any, UserConfig?: any, QueueConfig?: any, PhoneConfig?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($quick_connect_id | is-empty) { error make --unspanned { msg: "path parameter 'QuickConnectId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), quick_connect_id: (encode-path-segment $quick_connect_id)} | format pattern "/quick-connects/{instance_id}/{quick_connect_id}/config"))
  let req_body = {"QuickConnectConfig": $quick_connect_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the name and description of a quick connect. The request accepts the following data in JSON format. At least Name or Description must be provided.
#
# POST /quick-connects/{InstanceId}/{QuickConnectId}/name
# operationId: UpdateQuickConnectName
export def "quick-connects-name update" [
  instance_id: string
  quick_connect_id: string
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
  --name: string # The name of the quick connect.
  --description: string # The description of the quick connect.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($quick_connect_id | is-empty) { error make --unspanned { msg: "path parameter 'QuickConnectId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), quick_connect_id: (encode-path-segment $quick_connect_id)} | format pattern "/quick-connects/{instance_id}/{quick_connect_id}/name"))
  let req_body = {"Name": $name, "Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the channels that agents can handle in the Contact Control Panel (CCP) for a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/concurrency
# operationId: UpdateRoutingProfileConcurrency
# --MediaConcurrencies item shape: {Channel: any, Concurrency: any, CrossChannelBehavior?: any}
export def "routing-profiles-concurrency update" [
  instance_id: string
  routing_profile_id: string
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
  media_concurrencies: list # The channels that agents can handle in the Contact Control Panel (CCP). — item shape: {Channel: any, Concurrency: any, CrossChannelBehavior?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($routing_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'RoutingProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), routing_profile_id: (encode-path-segment $routing_profile_id)} | format pattern "/routing-profiles/{instance_id}/{routing_profile_id}/concurrency"))
  let req_body = {"MediaConcurrencies": $media_concurrencies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the default outbound queue of a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/default-outbound-queue
# operationId: UpdateRoutingProfileDefaultOutboundQueue
export def "routing-profiles-default-outbound-queue update" [
  instance_id: string
  routing_profile_id: string
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
  default_outbound_queue_id: string # The identifier for the default outbound queue.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($routing_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'RoutingProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), routing_profile_id: (encode-path-segment $routing_profile_id)} | format pattern "/routing-profiles/{instance_id}/{routing_profile_id}/default-outbound-queue"))
  let req_body = {"DefaultOutboundQueueId": $default_outbound_queue_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the name and description of a routing profile. The request accepts the following data in JSON format. At least Name or Description must be provided.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/name
# operationId: UpdateRoutingProfileName
export def "routing-profiles-name update" [
  instance_id: string
  routing_profile_id: string
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
  --name: string # The name of the routing profile. Must not be more than 127 characters.
  --description: string # The description of the routing profile. Must not be more than 250 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($routing_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'RoutingProfileId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), routing_profile_id: (encode-path-segment $routing_profile_id)} | format pattern "/routing-profiles/{instance_id}/{routing_profile_id}/name"))
  let req_body = {"Name": $name, "Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Assigns the specified hierarchy group to the specified user.
#
# POST /users/{InstanceId}/{UserId}/hierarchy
# operationId: UpdateUserHierarchy
export def "users-hierarchy update" [
  instance_id: string
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
  --hierarchy-group-id: string # The identifier of the hierarchy group.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), user_id: (encode-path-segment $user_id)} | format pattern "/users/{instance_id}/{user_id}/hierarchy"))
  let req_body = {"HierarchyGroupId": $hierarchy_group_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the name of the user hierarchy group.
#
# POST /user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}/name
# operationId: UpdateUserHierarchyGroupName
export def "user-hierarchy-groups-name update" [
  instance_id: string
  hierarchy_group_id: string
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
  name: string # The name of the hierarchy group. Must not be more than 100 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($hierarchy_group_id | is-empty) { error make --unspanned { msg: "path parameter 'HierarchyGroupId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), hierarchy_group_id: (encode-path-segment $hierarchy_group_id)} | format pattern "/user-hierarchy-groups/{instance_id}/{hierarchy_group_id}/name"))
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the identity information for the specified user. We strongly recommend limiting who has the ability to invoke UpdateUserIdentityInfo. Someone with that ability can change the login credentials of other users by changing their email address. This poses a security risk to your organization. They can change the email address of a user to the attacker's email address, and then reset the password through email. For more information, see Best Practices for Security Profiles (https://docs.aws.amazon.com/connect/latest/adminguide/security-profile-best-practices.html) in the Amazon Connect Administrator Guide.
#
# POST /users/{InstanceId}/{UserId}/identity-info
# operationId: UpdateUserIdentityInfo
# --IdentityInfo shape: {FirstName?: any, LastName?: any, Email?: any, SecondaryEmail?: any, Mobile?: any}
export def "users-identity-info update" [
  instance_id: string
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
  identity_info: record # Contains information about the identity of a user. — shape: {FirstName?: any, LastName?: any, Email?: any, SecondaryEmail?: any, Mobile?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), user_id: (encode-path-segment $user_id)} | format pattern "/users/{instance_id}/{user_id}/identity-info"))
  let req_body = {"IdentityInfo": $identity_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the phone configuration settings for the specified user.
#
# POST /users/{InstanceId}/{UserId}/phone-config
# operationId: UpdateUserPhoneConfig
# --PhoneConfig shape: {PhoneType?: any, AutoAccept?: any, AfterContactWorkTimeLimit?: any, DeskPhoneNumber?: any}
export def "users-phone-config update" [
  instance_id: string
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
  phone_config: record # Contains information about the phone configuration settings for a user. — shape: {PhoneType?: any, AutoAccept?: any, AfterContactWorkTimeLimit?: any, DeskPhoneNumber?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), user_id: (encode-path-segment $user_id)} | format pattern "/users/{instance_id}/{user_id}/phone-config"))
  let req_body = {"PhoneConfig": $phone_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Assigns the specified routing profile to the specified user.
#
# POST /users/{InstanceId}/{UserId}/routing-profile
# operationId: UpdateUserRoutingProfile
export def "users-routing-profile update" [
  instance_id: string
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
  routing_profile_id: string # The identifier of the routing profile for the user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), user_id: (encode-path-segment $user_id)} | format pattern "/users/{instance_id}/{user_id}/routing-profile"))
  let req_body = {"RoutingProfileId": $routing_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Assigns the specified security profiles to the specified user.
#
# POST /users/{InstanceId}/{UserId}/security-profiles
# operationId: UpdateUserSecurityProfiles
export def "users-security-profiles update" [
  instance_id: string
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
  security_profile_ids: list<string> # The identifiers of the security profiles for the user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'InstanceId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({instance_id: (encode-path-segment $instance_id), user_id: (encode-path-segment $user_id)} | format pattern "/users/{instance_id}/{user_id}/security-profiles"))
  let req_body = {"SecurityProfileIds": $security_profile_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
