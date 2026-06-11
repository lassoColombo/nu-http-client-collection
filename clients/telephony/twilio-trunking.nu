# Auto-generated client for Twilio - Trunking v1.0.0
# Source: https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_trunking_v1.json
# Auth: --token flag or $env.TWILIO_TRUNKING_TOKEN

const BASE_URL = "https://trunking.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_TRUNKING_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://trunking.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def Mode-completer [] { ["do-not-record" "record-from-answer" "record-from-answer-dual" "record-from-ringing" "record-from-ringing-dual"] }
def Trim-completer [] { ["do-not-trim" "trim-silence"] }
def DisasterRecoveryMethod-completer [] { ["GET" "POST"] }
def TransferMode-completer [] { ["disable-all" "enable-all" "sip-only"] }
def TransferCallerId-completer [] { ["from-transferee" "from-transferor"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "trunks-credential-lists FetchCredentialList" } } | get name | first)
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

# GET /v1/Trunks/{TrunkSid}/CredentialLists/{Sid}
#
# operationId: FetchCredentialList
export def "trunks-credential-lists FetchCredentialList" [
  TrunkSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, sid: string, trunk_sid: string, friendly_name: string, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/CredentialLists/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /v1/Trunks/{TrunkSid}/CredentialLists/{Sid}
#
# operationId: DeleteCredentialList
export def "trunks-credential-lists DeleteCredentialList" [
  TrunkSid: string
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
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/CredentialLists/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Trunks/{TrunkSid}/CredentialLists
#
# operationId: CreateCredentialList
export def "trunks-credential-lists CreateCredentialList" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  CredentialListSid: string # The SID of the [Credential List](https://www.twilio.com/docs/voice/sip/api/sip-credentiallist-resource) that you want to associate with the trunk. Once associated, we will authenticate access to the trunk against this list.
]: any -> record<account_sid: string, sid: string, trunk_sid: string, friendly_name: string, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/CredentialLists")
  let body = {CredentialListSid: $CredentialListSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Trunks/{TrunkSid}/CredentialLists
#
# operationId: ListCredentialList
export def "trunks-credential-lists ListCredentialList" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<credential_lists: table<account_sid: string, sid: string, trunk_sid: string, friendly_name: string, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/CredentialLists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Trunks/{TrunkSid}/IpAccessControlLists/{Sid}
#
# operationId: FetchIpAccessControlList
export def "trunks-ip-access-control-lists FetchIpAccessControlList" [
  TrunkSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, sid: string, trunk_sid: string, friendly_name: string, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/IpAccessControlLists/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an associated IP Access Control List from a Trunk
#
# DELETE /v1/Trunks/{TrunkSid}/IpAccessControlLists/{Sid}
# operationId: DeleteIpAccessControlList
export def "trunks-ip-access-control-lists DeleteIpAccessControlList" [
  TrunkSid: string
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
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/IpAccessControlLists/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate an IP Access Control List with a Trunk
#
# POST /v1/Trunks/{TrunkSid}/IpAccessControlLists
# operationId: CreateIpAccessControlList
export def "trunks-ip-access-control-lists CreateIpAccessControlList" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  IpAccessControlListSid: string # The SID of the [IP Access Control List](https://www.twilio.com/docs/voice/sip/api/sip-ipaccesscontrollist-resource) that you want to associate with the trunk.
]: any -> record<account_sid: string, sid: string, trunk_sid: string, friendly_name: string, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/IpAccessControlLists")
  let body = {IpAccessControlListSid: $IpAccessControlListSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all IP Access Control Lists for a Trunk
#
# GET /v1/Trunks/{TrunkSid}/IpAccessControlLists
# operationId: ListIpAccessControlList
export def "trunks-ip-access-control-lists ListIpAccessControlList" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<ip_access_control_lists: table<account_sid: string, sid: string, trunk_sid: string, friendly_name: string, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/IpAccessControlLists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Trunks/{TrunkSid}/OriginationUrls/{Sid}
#
# operationId: FetchOriginationUrl
export def "trunks-origination-urls FetchOriginationUrl" [
  TrunkSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, sid: string, trunk_sid: string, weight: int, enabled: bool, sip_url: string, friendly_name: string, priority: int, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/OriginationUrls/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /v1/Trunks/{TrunkSid}/OriginationUrls/{Sid}
#
# operationId: DeleteOriginationUrl
export def "trunks-origination-urls DeleteOriginationUrl" [
  TrunkSid: string
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
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/OriginationUrls/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Trunks/{TrunkSid}/OriginationUrls/{Sid}
#
# operationId: UpdateOriginationUrl
export def "trunks-origination-urls UpdateOriginationUrl" [
  TrunkSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Weight: int # The value that determines the relative share of the load the URI should receive compared to other URIs with the same priority. Can be an integer from 1 to 65535, inclusive, and the default is 10. URLs with higher values receive more load than those with lower ones with the same priority.
  --Priority: int # The relative importance of the URI. Can be an integer from 0 to 65535, inclusive, and the default is 10. The lowest number represents the most important URI.
  --Enabled: string@bool-completer # Whether the URL is enabled. The default is `true`.
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --SipUrl: string # The SIP address you want Twilio to route your Origination calls to. This must be a `sip:` schema. `sips` is NOT supported. (format: uri)
]: any -> record<account_sid: string, sid: string, trunk_sid: string, weight: int, enabled: bool, sip_url: string, friendly_name: string, priority: int, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/OriginationUrls/($Sid)")
  let body = {Weight: $Weight, Priority: $Priority, Enabled: $Enabled, FriendlyName: $FriendlyName, SipUrl: $SipUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /v1/Trunks/{TrunkSid}/OriginationUrls
#
# operationId: CreateOriginationUrl
export def "trunks-origination-urls CreateOriginationUrl" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Weight: int # The value that determines the relative share of the load the URI should receive compared to other URIs with the same priority. Can be an integer from 1 to 65535, inclusive, and the default is 10. URLs with higher values receive more load than those with lower ones with the same priority.
  Priority: int # The relative importance of the URI. Can be an integer from 0 to 65535, inclusive, and the default is 10. The lowest number represents the most important URI.
  --Enabled: string@bool-completer # Whether the URL is enabled. The default is `true`.
  FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  SipUrl: string # The SIP address you want Twilio to route your Origination calls to. This must be a `sip:` schema. (format: uri)
]: any -> record<account_sid: string, sid: string, trunk_sid: string, weight: int, enabled: bool, sip_url: string, friendly_name: string, priority: int, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/OriginationUrls")
  let body = {Weight: $Weight, Priority: $Priority, Enabled: $Enabled, FriendlyName: $FriendlyName, SipUrl: $SipUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Trunks/{TrunkSid}/OriginationUrls
#
# operationId: ListOriginationUrl
export def "trunks-origination-urls ListOriginationUrl" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<origination_urls: table<account_sid: string, sid: string, trunk_sid: string, weight: int, enabled: bool, sip_url: string, friendly_name: string, priority: int, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/OriginationUrls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Trunks/{TrunkSid}/PhoneNumbers/{Sid}
#
# operationId: FetchPhoneNumber
export def "trunks-phone-numbers FetchPhoneNumber" [
  TrunkSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record<mms: bool, sms: bool, voice: bool, fax: bool>, date_created: string, date_updated: string, friendly_name: string, links: record, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, url: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/PhoneNumbers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /v1/Trunks/{TrunkSid}/PhoneNumbers/{Sid}
#
# operationId: DeletePhoneNumber
export def "trunks-phone-numbers DeletePhoneNumber" [
  TrunkSid: string
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
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/PhoneNumbers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Trunks/{TrunkSid}/PhoneNumbers
#
# operationId: CreatePhoneNumber
export def "trunks-phone-numbers CreatePhoneNumber" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  PhoneNumberSid: string # The SID of the [Incoming Phone Number](https://www.twilio.com/docs/phone-numbers/api/incomingphonenumber-resource) that you want to associate with the trunk.
]: any -> record<account_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record<mms: bool, sms: bool, voice: bool, fax: bool>, date_created: string, date_updated: string, friendly_name: string, links: record, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, url: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/PhoneNumbers")
  let body = {PhoneNumberSid: $PhoneNumberSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Trunks/{TrunkSid}/PhoneNumbers
#
# operationId: ListPhoneNumber
export def "trunks-phone-numbers ListPhoneNumber" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<phone_numbers: table<account_sid: string, address_requirements: string, api_version: string, beta: bool, capabilities: record, date_created: string, date_updated: string, friendly_name: string, links: record, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, url: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/PhoneNumbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Trunks/{TrunkSid}/Recording
#
# operationId: FetchRecording
export def "trunks-recording FetchRecording" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<mode: string, trim: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/Recording")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Trunks/{TrunkSid}/Recording
#
# operationId: UpdateRecording
export def "trunks-recording UpdateRecording" [
  TrunkSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Mode: string@Mode-completer # The recording mode for the trunk. Can be do-not-record (default), record-from-ringing, record-from-answer, record-from-ringing-dual, or record-from-answer-dual.
  --Trim: string@Trim-completer # The recording trim setting for the trunk. Can be do-not-trim (default) or trim-silence.
]: any -> record<mode: string, trim: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($TrunkSid)/Recording")
  let body = {Mode: $Mode, Trim: $Trim} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Trunks/{Sid}
#
# operationId: FetchTrunk
export def "trunks FetchTrunk" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, domain_name: string, disaster_recovery_method: string, disaster_recovery_url: string, friendly_name: string, secure: bool, recording: any, transfer_mode: string, transfer_caller_id: string, cnam_lookup_enabled: bool, auth_type: string, symmetric_rtp_enabled: bool, auth_type_set: list<string>, date_created: string, date_updated: string, sid: string, url: string, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /v1/Trunks/{Sid}
#
# operationId: DeleteTrunk
export def "trunks DeleteTrunk" [
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
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Trunks/{Sid}
#
# operationId: UpdateTrunk
export def "trunks UpdateTrunk" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --DomainName: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and `-` and must end with `pstn.twilio.com`. See [Termination Settings](https://www.twilio.com/docs/sip-trunking#termination) for more information.
  --DisasterRecoveryUrl: string # The URL we should call using the `disaster_recovery_method` if an error occurs while sending SIP traffic towards the configured Origination URL. We retrieve TwiML from the URL and execute the instructions like any other normal TwiML call. See [Disaster Recovery](https://www.twilio.com/docs/sip-trunking#disaster-recovery) for more information. (format: uri)
  --DisasterRecoveryMethod: string@DisasterRecoveryMethod-completer # The HTTP method we should use to call the `disaster_recovery_url`. Can be: `GET` or `POST`. (format: http-method)
  --TransferMode: string@TransferMode-completer # The call transfer settings for the trunk. Can be: `enable-all`, `sip-only` and `disable-all`. See [Transfer](https://www.twilio.com/docs/sip-trunking/call-transfer) for more information.
  --Secure: string@bool-completer # Whether Secure Trunking is enabled for the trunk. If enabled, all calls going through the trunk will be secure using SRTP for media and TLS for signaling. If disabled, then RTP will be used for media. See [Secure Trunking](https://www.twilio.com/docs/sip-trunking#securetrunking) for more information.
  --CnamLookupEnabled: string@bool-completer # Whether Caller ID Name (CNAM) lookup should be enabled for the trunk. If enabled, all inbound calls to the SIP Trunk from the United States and Canada automatically perform a CNAM Lookup and display Caller ID data on your phone. See [CNAM Lookups](https://www.twilio.com/docs/sip-trunking#CNAM) for more information.
  --TransferCallerId: string@TransferCallerId-completer # Caller Id for transfer target. Can be: `from-transferee` (default) or `from-transferor`.
]: any -> record<account_sid: string, domain_name: string, disaster_recovery_method: string, disaster_recovery_url: string, friendly_name: string, secure: bool, recording: any, transfer_mode: string, transfer_caller_id: string, cnam_lookup_enabled: bool, auth_type: string, symmetric_rtp_enabled: bool, auth_type_set: list<string>, date_created: string, date_updated: string, sid: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base $"/v1/Trunks/($Sid)")
  let body = {FriendlyName: $FriendlyName, DomainName: $DomainName, DisasterRecoveryUrl: $DisasterRecoveryUrl, DisasterRecoveryMethod: $DisasterRecoveryMethod, TransferMode: $TransferMode, Secure: $Secure, CnamLookupEnabled: $CnamLookupEnabled, TransferCallerId: $TransferCallerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /v1/Trunks
#
# operationId: CreateTrunk
export def "trunks CreateTrunk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --DomainName: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and `-` and must end with `pstn.twilio.com`. See [Termination Settings](https://www.twilio.com/docs/sip-trunking#termination) for more information.
  --DisasterRecoveryUrl: string # The URL we should call using the `disaster_recovery_method` if an error occurs while sending SIP traffic towards the configured Origination URL. We retrieve TwiML from the URL and execute the instructions like any other normal TwiML call. See [Disaster Recovery](https://www.twilio.com/docs/sip-trunking#disaster-recovery) for more information. (format: uri)
  --DisasterRecoveryMethod: string@DisasterRecoveryMethod-completer # The HTTP method we should use to call the `disaster_recovery_url`. Can be: `GET` or `POST`. (format: http-method)
  --TransferMode: string@TransferMode-completer # The call transfer settings for the trunk. Can be: `enable-all`, `sip-only` and `disable-all`. See [Transfer](https://www.twilio.com/docs/sip-trunking/call-transfer) for more information.
  --Secure: string@bool-completer # Whether Secure Trunking is enabled for the trunk. If enabled, all calls going through the trunk will be secure using SRTP for media and TLS for signaling. If disabled, then RTP will be used for media. See [Secure Trunking](https://www.twilio.com/docs/sip-trunking#securetrunking) for more information.
  --CnamLookupEnabled: string@bool-completer # Whether Caller ID Name (CNAM) lookup should be enabled for the trunk. If enabled, all inbound calls to the SIP Trunk from the United States and Canada automatically perform a CNAM Lookup and display Caller ID data on your phone. See [CNAM Lookups](https://www.twilio.com/docs/sip-trunking#CNAM) for more information.
  --TransferCallerId: string@TransferCallerId-completer # Caller Id for transfer target. Can be: `from-transferee` (default) or `from-transferor`.
]: any -> record<account_sid: string, domain_name: string, disaster_recovery_method: string, disaster_recovery_url: string, friendly_name: string, secure: bool, recording: any, transfer_mode: string, transfer_caller_id: string, cnam_lookup_enabled: bool, auth_type: string, symmetric_rtp_enabled: bool, auth_type_set: list<string>, date_created: string, date_updated: string, sid: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let full_url = (build-url $base "/v1/Trunks")
  let body = {FriendlyName: $FriendlyName, DomainName: $DomainName, DisasterRecoveryUrl: $DisasterRecoveryUrl, DisasterRecoveryMethod: $DisasterRecoveryMethod, TransferMode: $TransferMode, Secure: $Secure, CnamLookupEnabled: $CnamLookupEnabled, TransferCallerId: $TransferCallerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Trunks
#
# operationId: ListTrunk
export def "trunks ListTrunk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<trunks: table<account_sid: string, domain_name: string, disaster_recovery_method: string, disaster_recovery_url: string, friendly_name: string, secure: bool, recording: any, transfer_mode: string, transfer_caller_id: string, cnam_lookup_enabled: bool, auth_type: string, symmetric_rtp_enabled: bool, auth_type_set: list, date_created: string, date_updated: string, sid: string, url: string, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://trunking.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Trunks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
