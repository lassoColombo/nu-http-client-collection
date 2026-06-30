# Auto-generated client for Swiss NextGen Banking API-Framework v1.3.8_2020-12-14 - Swiss edition 1.3.8.1-CH
# Source: https://api.apis.guru/v2/specs/openbankingproject.ch/1.3.8_2020-12-14 - Swiss edition 1.3.8.1-CH/openapi.json
# Auth: --token flag or $env.SWISS_NEXTGEN_BANKING_API_FRAMEWORK_TOKEN

const BASE_URL = "https://api.dev.openbankingproject.ch"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SWISS_NEXTGEN_BANKING_API_FRAMEWORK_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.dev.openbankingproject.ch"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def psu-http-method-completer [] { ["DELETE" "GET" "PATCH" "POST" "PUT"] }
def booking-status-completer [] { ["booked" "both" "information" "pending"] }
def charge-bearer-completer [] { ["CRED" "DEBT" "SHAR" "SLEV"] }
def purpose-code-completer [] { ["PENS" "SALA"] }
def service-level-completer [] { ["PRPT" "SDVA" "SEPA" "URGP"] }
def day-of-execution-completer [] { ["1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "2" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "3" "30" "31" "4" "5" "6" "7" "8" "9"] }
def execution-rule-completer [] { ["following" "preceding"] }
def frequency-completer [] { ["Annual" "Daily" "EveryTwoMonths" "EveryTwoWeeks" "Monthly" "MonthlyVariable" "Quarterly" "SemiAnnual" "Weekly"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts get-list" } } | get name | first)
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

# Read account list
#
# GET /v1/accounts
# operationId: getAccountList
export def "accounts get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-balance: oneof<nothing, bool> # If contained, this function reads the list of accessible payment accounts including the booking balance, if granted by the PSU in the related consent and available by the ASPSP. This parameter might be ignored by the ASPSP.
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withBalance" $with_balance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/accounts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "Consent-ID": $consent_id, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"withBalance": $with_balance} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Read account details
#
# GET /v1/accounts/{account-id}
# operationId: readAccountDetails
export def "accounts get-details" [
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
  --with-balance: oneof<nothing, bool> # If contained, this function reads the list of accessible payment accounts including the booking balance, if granted by the PSU in the related consent and available by the ASPSP. This parameter might be ignored by the ASPSP.
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account-id' must be non-empty" } }
  let qp = [(serialize-qp "withBalance" $with_balance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v1/accounts/{account_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "Consent-ID": $consent_id, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"withBalance": $with_balance} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Read balance
#
# GET /v1/accounts/{account-id}/balances
# operationId: getBalances
export def "accounts-balances get" [
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
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account-id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v1/accounts/{account_id}/balances") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "Consent-ID": $consent_id, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Read transaction list of an account
#
# GET /v1/accounts/{account-id}/transactions
# operationId: getTransactionList
export def "accounts-transactions get-list" [
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
  --date-from: string # Conditional: Starting date (inclusive the date dateFrom) of the transaction list, mandated if no delta access is required and if bookingStatus does not equal "information". For booked transactions, the relevant date is the booking date. For pending transactions, the relevant date is the entry date, which may not be transparent neither in this API nor other channels of the ASPSP. (format: date)
  --date-to: string # End date (inclusive the data dateTo) of the transaction list, default is "now" if not given. Might be ignored if a delta function is used. For booked transactions, the relevant date is the booking date. For pending transactions, the relevant date is the entry date, which may not be transparent neither in this API nor other channels of the ASPSP. (format: date)
  --entry-reference-from: string # This data attribute is indicating that the AISP is in favour to get all transactions after the transaction with identification entryReferenceFrom alternatively to the above defined period. This is a implementation of a delta access. If this data element is contained, the entries "dateFrom" and "dateTo" might be ignored by the ASPSP if a delta report is supported. Optional if supported by API provider.
  --booking-status: string@booking-status-completer # Permitted codes are * "information", * "booked", * "pending", and * "both" "booked" shall be supported by the ASPSP. To support the "pending" and "both" feature is optional for the ASPSP, Error code if not supported in the online banking frontend
  --delta-list: oneof<nothing, bool> # This data attribute is indicating that the AISP is in favour to get all transactions after the last report access for this PSU on the addressed account. This is another implementation of a delta access-report. This delta indicator might be rejected by the ASPSP if this function is not supported. Optional if supported by API provider
  --with-balance: oneof<nothing, bool> # If contained, this function reads the list of accessible payment accounts including the booking balance, if granted by the PSU in the related consent and available by the ASPSP. This parameter might be ignored by the ASPSP.
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account-id' must be non-empty" } }
  let qp = [(serialize-qp "dateFrom" $date_from "scalar") (serialize-qp "dateTo" $date_to "scalar") (serialize-qp "entryReferenceFrom" $entry_reference_from "scalar") (serialize-qp "bookingStatus" $booking_status "scalar") (serialize-qp "deltaList" $delta_list "scalar") (serialize-qp "withBalance" $with_balance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/v1/accounts/{account_id}/transactions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "Consent-ID": $consent_id, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"dateFrom": $date_from, "dateTo": $date_to, "entryReferenceFrom": $entry_reference_from, "bookingStatus": $booking_status, "deltaList": $delta_list, "withBalance": $with_balance} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Read transaction details
#
# GET /v1/accounts/{account-id}/transactions/{transactionId}
# operationId: getTransactionDetails
export def "accounts-transactions get-details" [
  account_id: string
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
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --consent-id: string # This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account-id' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/v1/accounts/{account_id}/transactions/{transaction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "Consent-ID": $consent_id, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Create consent
#
# POST /v1/consents
# operationId: createConsent
# --access shape: {accounts?: list, additionalInformation?: record, allPsd2?: "allAccounts"|"allAccountsWithOwnerName", availableAccounts?: "allAccounts"|"allAccountsWithOwnerName", availableAccountsWithBalance?: "allAccounts"|"allAccountsWithOwnerName", balances?: list, restrictedTo?: list<string>, transactions?: list}
export def "consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification.
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP.
  --tpp-explicit-authorisation-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers to start the authorisation process separately, e.g. because of the usage of a signing basket. This preference might be ignored by the ASPSP, if a signing basket is not supported as functionality. If it equals "false" or if the parameter is not used, there is no preference of the TPP. This especially indicates that the TPP assumes a direct authorisation of the transaction in the next step, without using a signing basket.
  --tpp-brand-logging-information: string # This header might be used by TPPs to inform the ASPSP about the brand used by the TPP towards the PSU. This information is meant for logging entries to enhance communication between ASPSP and PSU or ASPSP and TPP. This header might be ignored by the ASPSP.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. If not available, the TPP shall use the IP Address used by the TPP when submitting this request. (e.g. 192.168.8.78)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  access: record # Requested access services for a consent. — shape: {accounts?: list, additionalInformation?: record, allPsd2?: "allAccounts"|"allAccountsWithOwnerName", availableAccounts?: "allAccounts"|"allAccountsWithOwnerName", availableAccountsWithBalance?: "allAccounts"|"allAccountsWithOwnerName", balances?: list, restrictedTo?: list<string>, transactions?: list}
  --combined-service-indicator: oneof<nothing, bool> # If "true" indicates that a payment initiation service will be addressed in the same "session". (e.g. false)
  frequency_per_day: int # This field indicates the requested maximum frequency for an access without PSU involvement per day. For a one-off access, this attribute is set to "1". The frequency needs to be greater equal to one. If not otherwise agreed bilaterally between TPP and ASPSP, the frequency is less equal to 4. (e.g. 4)
  --recurring-indicator: oneof<nothing, bool> # "true", if the consent is for recurring access to the account data. "false", if the consent is for one access to the account data. (e.g. false)
  valid_until: string # This parameter is defining a valid until date (including the mentioned date) for the requested consent. The content is the local ASPSP date in ISO-Date format, e.g. 2017-10-30. Future dates might get adjusted by ASPSP. If a maximal available date is requested, a date in far future is to be used: "9999-12-31". In both cases the consent object to be retrieved by the get consent request will contain the adjusted date. (format: date, e.g. 2020-12-31)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/consents" $auth.query)
  let req_body = {"access": $access, "combinedServiceIndicator": $combined_service_indicator, "frequencyPerDay": $frequency_per_day, "recurringIndicator": $recurring_indicator, "validUntil": $valid_until} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "TPP-Redirect-Preferred": $tpp_redirect_preferred, "TPP-Redirect-URI": $tpp_redirect_uri, "TPP-Nok-Redirect-URI": $tpp_nok_redirect_uri, "TPP-Explicit-Authorisation-Preferred": $tpp_explicit_authorisation_preferred, "TPP-Brand-Logging-Information": $tpp_brand_logging_information, "TPP-Notification-URI": $tpp_notification_uri, "TPP-Notification-Content-Preferred": $tpp_notification_content_preferred, "PSU-IP-Port": $psu_ip_port, "PSU-IP-Address": $psu_ip_address, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Delete Consent
#
# DELETE /v1/consents/{consentId}
# operationId: deleteConsent
export def "consents delete" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'consentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/v1/consents/{consent_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Get consent request
#
# GET /v1/consents/{consentId}
# operationId: getConsentInformation
export def "consents get-information" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'consentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/v1/consents/{consent_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Get consent authorisation sub-resources request
#
# GET /v1/consents/{consentId}/authorisations
# operationId: getConsentAuthorisation
export def "consents-authorisations get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'consentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/v1/consents/{consent_id}/authorisations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Start the authorisation process for a consent
#
# POST /v1/consents/{consentId}/authorisations
# operationId: startConsentAuthorisation
# --psuData shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
export def "consents-authorisations start" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification.
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'consentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/v1/consents/{consent_id}/authorisations") $auth.query)
  let req_body = {"psuData": $psu_data, "authenticationMethodId": $authentication_method_id, "scaAuthenticationData": $sca_authentication_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "TPP-Redirect-Preferred": $tpp_redirect_preferred, "TPP-Redirect-URI": $tpp_redirect_uri, "TPP-Nok-Redirect-URI": $tpp_nok_redirect_uri, "TPP-Notification-URI": $tpp_notification_uri, "TPP-Notification-Content-Preferred": $tpp_notification_content_preferred, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Read the SCA status of the consent authorisation
#
# GET /v1/consents/{consentId}/authorisations/{authorisationId}
# operationId: getConsentScaStatus
export def "consents-authorisations get-sca-status" [
  consent_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'consentId' must be non-empty" } }
  if ($authorisation_id | is-empty) { error make --unspanned { msg: "path parameter 'authorisationId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id), authorisation_id: (encode-path-segment $authorisation_id)} | format pattern "/v1/consents/{consent_id}/authorisations/{authorisation_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Update PSU Data for consents
#
# PUT /v1/consents/{consentId}/authorisations/{authorisationId}
# operationId: updateConsentsPsuData
# --psuData shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
export def "consents-authorisations update-psu-data" [
  consent_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
  --confirmation-code: string # Confirmation Code as retrieved by the TPP from the redirect based SCA process.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'consentId' must be non-empty" } }
  if ($authorisation_id | is-empty) { error make --unspanned { msg: "path parameter 'authorisationId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id), authorisation_id: (encode-path-segment $authorisation_id)} | format pattern "/v1/consents/{consent_id}/authorisations/{authorisation_id}") $auth.query)
  let req_body = {"psuData": $psu_data, "authenticationMethodId": $authentication_method_id, "scaAuthenticationData": $sca_authentication_data, "confirmationCode": $confirmation_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Consent status request
#
# GET /v1/consents/{consentId}/status
# operationId: getConsentStatus
export def "consents-status get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding HTTP request IP Address field between PSU and TPP. It shall be contained if and only if this request was actively initiated by the PSU. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'consentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/v1/consents/{consent_id}/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Confirmation of funds request
#
# POST /v1/funds-confirmations
# operationId: checkAvailabilityOfFunds
# --account shape: {cashAccountType?: string, currency?: string, iban?: string, otherAccountIdentification?: string}
# --instructedAmount shape: {amount: string, currency: string}
export def "funds-confirmations check-availability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --authorization: string # This field might be used in case where a consent was agreed between ASPSP and PSU through an OAuth2 based protocol, facilitated by the TPP.
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  account: record # Reference to an account by either * IBAN, of a payment accounts, or * otherAccountIdentification, for payment accounts if there is no IBAN adapted from ISO pain.001.001.03.ch.02 CashAccount16-CH_IdTpCcy — shape: {cashAccountType?: string, currency?: string, iban?: string, otherAccountIdentification?: string}
  --card-number: string # Card Number of the card issued by the PIISP. Should be delivered if available.
  instructed_amount: record # e.g. {amount: 123, currency: EUR} — shape: {amount: string, currency: string}
  --payee: string # Name payee.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/funds-confirmations" $auth.query)
  let req_body = {"account": $account, "cardNumber": $card_number, "instructedAmount": $instructed_amount, "payee": $payee} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Authorization": $authorization, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate} | compact
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

# Create a signing basket resource
#
# POST /v1/signing-baskets
# operationId: createSigningBasket
export def "signing-baskets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --consent-id: string # This data element may be contained, if the payment initiation transaction is part of a session, i.e. combined AIS/PIS service. This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. If not available, the TPP shall use the IP Address used by the TPP when submitting this request. (e.g. 192.168.8.78)
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification.
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP.
  --tpp-explicit-authorisation-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers to start the authorisation process separately, e.g. because of the usage of a signing basket. This preference might be ignored by the ASPSP, if a signing basket is not supported as functionality. If it equals "false" or if the parameter is not used, there is no preference of the TPP. This especially indicates that the TPP assumes a direct authorisation of the transaction in the next step, without using a signing basket.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --consent-ids: list<string> # A list of consentIds.
  --payment-ids: list<string> # A list of paymentIds.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/signing-baskets" $auth.query)
  let req_body = {"consentIds": $consent_ids, "paymentIds": $payment_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "Consent-ID": $consent_id, "PSU-IP-Address": $psu_ip_address, "TPP-Redirect-Preferred": $tpp_redirect_preferred, "TPP-Redirect-URI": $tpp_redirect_uri, "TPP-Nok-Redirect-URI": $tpp_nok_redirect_uri, "TPP-Explicit-Authorisation-Preferred": $tpp_explicit_authorisation_preferred, "TPP-Notification-URI": $tpp_notification_uri, "TPP-Notification-Content-Preferred": $tpp_notification_content_preferred, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Delete the signing basket
#
# DELETE /v1/signing-baskets/{basketId}
# operationId: deleteSigningBasket
export def "signing-baskets delete" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($basket_id | is-empty) { error make --unspanned { msg: "path parameter 'basketId' must be non-empty" } }
  let full_url = (build-url $base ({basket_id: (encode-path-segment $basket_id)} | format pattern "/v1/signing-baskets/{basket_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Returns the content of an signing basket object
#
# GET /v1/signing-baskets/{basketId}
# operationId: getSigningBasket
export def "signing-baskets get" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($basket_id | is-empty) { error make --unspanned { msg: "path parameter 'basketId' must be non-empty" } }
  let full_url = (build-url $base ({basket_id: (encode-path-segment $basket_id)} | format pattern "/v1/signing-baskets/{basket_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Get signing basket authorisation sub-resources request
#
# GET /v1/signing-baskets/{basketId}/authorisations
# operationId: getSigningBasketAuthorisation
export def "signing-baskets-authorisations get" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($basket_id | is-empty) { error make --unspanned { msg: "path parameter 'basketId' must be non-empty" } }
  let full_url = (build-url $base ({basket_id: (encode-path-segment $basket_id)} | format pattern "/v1/signing-baskets/{basket_id}/authorisations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Start the authorisation process for a signing basket
#
# POST /v1/signing-baskets/{basketId}/authorisations
# operationId: startSigningBasketAuthorisation
# --psuData shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
export def "signing-baskets-authorisations start" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification.
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($basket_id | is-empty) { error make --unspanned { msg: "path parameter 'basketId' must be non-empty" } }
  let full_url = (build-url $base ({basket_id: (encode-path-segment $basket_id)} | format pattern "/v1/signing-baskets/{basket_id}/authorisations") $auth.query)
  let req_body = {"psuData": $psu_data, "authenticationMethodId": $authentication_method_id, "scaAuthenticationData": $sca_authentication_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "TPP-Redirect-Preferred": $tpp_redirect_preferred, "TPP-Redirect-URI": $tpp_redirect_uri, "TPP-Nok-Redirect-URI": $tpp_nok_redirect_uri, "TPP-Notification-URI": $tpp_notification_uri, "TPP-Notification-Content-Preferred": $tpp_notification_content_preferred, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Read the SCA status of the signing basket authorisation
#
# GET /v1/signing-baskets/{basketId}/authorisations/{authorisationId}
# operationId: getSigningBasketScaStatus
export def "signing-baskets-authorisations get-sca-status" [
  basket_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($basket_id | is-empty) { error make --unspanned { msg: "path parameter 'basketId' must be non-empty" } }
  if ($authorisation_id | is-empty) { error make --unspanned { msg: "path parameter 'authorisationId' must be non-empty" } }
  let full_url = (build-url $base ({basket_id: (encode-path-segment $basket_id), authorisation_id: (encode-path-segment $authorisation_id)} | format pattern "/v1/signing-baskets/{basket_id}/authorisations/{authorisation_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Update PSU data for signing basket
#
# PUT /v1/signing-baskets/{basketId}/authorisations/{authorisationId}
# operationId: updateSigningBasketPsuData
# --psuData shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
export def "signing-baskets-authorisations update-psu-data" [
  basket_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
  --confirmation-code: string # Confirmation Code as retrieved by the TPP from the redirect based SCA process.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($basket_id | is-empty) { error make --unspanned { msg: "path parameter 'basketId' must be non-empty" } }
  if ($authorisation_id | is-empty) { error make --unspanned { msg: "path parameter 'authorisationId' must be non-empty" } }
  let full_url = (build-url $base ({basket_id: (encode-path-segment $basket_id), authorisation_id: (encode-path-segment $authorisation_id)} | format pattern "/v1/signing-baskets/{basket_id}/authorisations/{authorisation_id}") $auth.query)
  let req_body = {"psuData": $psu_data, "authenticationMethodId": $authentication_method_id, "scaAuthenticationData": $sca_authentication_data, "confirmationCode": $confirmation_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Read the status of the signing basket
#
# GET /v1/signing-baskets/{basketId}/status
# operationId: getSigningBasketStatus
export def "signing-baskets-status get" [
  basket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($basket_id | is-empty) { error make --unspanned { msg: "path parameter 'basketId' must be non-empty" } }
  let full_url = (build-url $base ({basket_id: (encode-path-segment $basket_id)} | format pattern "/v1/signing-baskets/{basket_id}/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Payment initiation request
#
# POST /v1/{payment-service}/{payment-product}
# operationId: initiatePayment
# --creditorAccount shape: {cashAccountType?: string, currency?: string, iban?: string, otherAccountIdentification?: string}
# --creditorAddress shape: {buildingNumber?: string, country: string, postCode?: string, streetName?: string, townName?: string}
# --creditorAgent shape: {address?: record, bic?: string, iid?: record, name?: string}
# --debtorAccount shape: {cashAccountType?: string, currency?: string, iban?: string, otherAccountIdentification?: string}
# --debtorAgent shape: {bic?: string, iid?: record}
# --equivalentAmount shape: {amount: string, currency: string}
# --exchangeRateInformation shape: {contractIdentification?: string, exchangeRate?: string, rateType?: "SPOT"|"SALE"|"AGRD"}
# --instructedAmount shape: {amount: string, currency: string}
# --remittanceInformationStructured shape: {SCORorQRRorIPI?: "SCOR"|"QRR"|"IPI", additionalRemittanceInformation?: string, reference: string, referenceIssuer?: string, referenceType?: string}
# --payments item shape: {chargeBearer?: "DEBT"|"CRED"|"SHAR"|"SLEV", creditorAccount: record, creditorAddress?: record, creditorAgent?: record, creditorAgentName?: string, creditorId?: string, creditorName: string, creditorNameAndAddress?: string, debtorId?: string, debtorName: string, endToEndIdentification: string, equivalentAmount?: record, exchangeRateInformation?: record, instructedAmount?: record, intermediaryAgent?: string, purposeCode?: "SALA"|"PENS", remittanceInformationStructured?: record, ... (5 more fields)}
export def "payment-initiation-service-pis create-initiate" [
  payment_service: string
  payment_product: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --consent-id: string # This data element may be contained, if the payment initiation transaction is part of a session, i.e. combined AIS/PIS service. This then contains the consentId of the related AIS consent, which was performed prior to this payment initiation.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. If not available, the TPP shall use the IP Address used by the TPP when submitting this request. (e.g. 192.168.8.78)
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification.
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP.
  --tpp-explicit-authorisation-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers to start the authorisation process separately, e.g. because of the usage of a signing basket. This preference might be ignored by the ASPSP, if a signing basket is not supported as functionality. If it equals "false" or if the parameter is not used, there is no preference of the TPP. This especially indicates that the TPP assumes a direct authorisation of the transaction in the next step, without using a signing basket.
  --tpp-rejection-no-funds-preferred: oneof<nothing, bool> # If it equals "true" then the TPP prefers a rejection of the payment initiation in case the ASPSP is providing an integrated confirmation of funds request an the result of this is that not sufficient funds are available. If it equals "false" then the TPP prefers that the ASPSP is dealing with the payment initiation like in the ASPSPs online channel, potentially waiting for a certain time period for funds to arrive to initiate the payment. This parameter might be ignored by the ASPSP.
  --tpp-brand-logging-information: string # This header might be used by TPPs to inform the ASPSP about the brand used by the TPP towards the PSU. This information is meant for logging entries to enhance communication between ASPSP and PSU or ASPSP and TPP. This header might be ignored by the ASPSP.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --charge-bearer: string@charge-bearer-completer # Charge Bearer. ChargeBearerType1Code from ISO20022.
  --creditor-account: record # Reference to an account by either * IBAN, of a payment accounts, or * otherAccountIdentification, for payment accounts if there is no IBAN adapted from ISO pain.001.001.03.ch.02 CashAccount16-CH_IdTpCcy — shape: {cashAccountType?: string, currency?: string, iban?: string, otherAccountIdentification?: string}
  --creditor-address: record # e.g. {buildingnNumber: 89, country: FR, postCode: 75000, streetName: rue blue, townName: Paris} — shape: {buildingNumber?: string, country: string, postCode?: string, streetName?: string, townName?: string}
  --creditor-agent: record # Reference to an creditorAgent by either * BIC, of the creditor bank, or * IID, of the creditor bank, or * IID and optional name and address of the creditor bank or * Name and address of the creditor bank adapted from ISO pain.001.001.03.ch.02 FinancialInstitutionIdentification7-CH — shape: {address?: record, bic?: string, iid?: record, name?: string}
  --creditor-agent-name: string # Creditor agent name. (e.g. Creditor Id 1234)
  --creditor-id: string # Identification of Creditors, e.g. a SEPA Creditor ID. (e.g. Creditor Id 5678)
  --creditor-name: string # Creditor name. (e.g. Creditor Name)
  --creditor-name-and-address: string # Creditor Name and Address in a free text field. (e.g. Max Masters, Main Street 1, 12345 City, Example Country)
  --debtor-account: record # Reference to an account by either * IBAN, of a payment accounts, or * otherAccountIdentification, for payment accounts if there is no IBAN adapted from ISO pain.001.001.03.ch.02 CashAccount16-CH_IdTpCcy — shape: {cashAccountType?: string, currency?: string, iban?: string, otherAccountIdentification?: string}
  --debtor-agent: record # Reference to an debtorAgent by either * BIC, of the debtor bank, or * IID, of the debtor bank adapted from ISO pain.001.001.03.ch.02 FinancialInstitutionIdentification7-CH_BicOrClrId — shape: {bic?: string, iid?: record}
  --debtor-id: string # Debtor Id. (e.g. Debtor Id 1234)
  --debtor-name: string # Debtor name. (e.g. Debtor Name)
  --end-to-end-identification: string
  --equivalent-amount: record # e.g. {amount: 123, currency: EUR} — shape: {amount: string, currency: string}
  --exchange-rate-information: record # as in ISO pain.001.001.03.ch.02 ExchangeRateInformation1 — shape: {contractIdentification?: string, exchangeRate?: string, rateType?: "SPOT"|"SALE"|"AGRD"}
  --instructed-amount: record # e.g. {amount: 123, currency: EUR} — shape: {amount: string, currency: string}
  --intermediary-agent: string # BICFI (e.g. AAAADEBBXXX)
  --purpose-code: string@purpose-code-completer # ExternalPurpose1Code from ISO 20022. Values from ISO 20022 External Code List ExternalCodeSets_1Q2018 June 2018.
  --remittance-information-structured: record # Structured remittance information. — shape: {SCORorQRRorIPI?: "SCOR"|"QRR"|"IPI", additionalRemittanceInformation?: string, reference: string, referenceIssuer?: string, referenceType?: string}
  --remittance-information-unstructured: string # Unstructured remittance information. (e.g. Ref Number Merchant)
  --requested-execution-date: string # format: date
  --service-level: string@service-level-completer # Specifies the external service level code in the format of character string with a maximum length of 4 characters.
  --transaction-currency: string # ISO 4217 Alpha 3 currency code. (e.g. EUR)
  --ultimate-creditor: string # Ultimate creditor. (e.g. Ultimate Creditor)
  --ultimate-debtor: string # Ultimate debtor. (e.g. Ultimate Debtor)
  --day-of-execution: string@day-of-execution-completer # Day of execution as string. This string consists of up two characters. Leading zeroes are not allowed. 31 is ultimo of the month.
  --end-date: string # The last applicable day of execution. If not given, it is an infinite standing order. (format: date)
  --execution-rule: string@execution-rule-completer # "following" or "preceding" supported as values. This data attribute defines the behaviour when recurring payment dates falls on a weekend or bank holiday. The payment is then executed either the "preceding" or "following" working day. ASPSP might reject the request due to the communicated value, if rules in Online-Banking are not supporting this execution rule.
  --frequency: string@frequency-completer # The following codes from the "EventFrequency7Code" of ISO 20022 are supported: - "Daily" - "Weekly" - "EveryTwoWeeks" - "Monthly" - "EveryTwoMonths" - "Quarterly" - "SemiAnnual" - "Annual" - "MonthlyVariable"
  --start-date: string # The first applicable day of execution starting from this date is the first payment. (format: date)
  --batch-booking-preferred: oneof<nothing, bool> # If this element equals 'true', the PSU prefers only one booking entry. If this element equals 'false', the PSU prefers individual booking of all contained individual transactions. The ASPSP will follow this preference according to contracts agreed on with the PSU. (e.g. false)
  --payments: list # A list of generic JSON bodies payment initations for bulk payments via JSON. Note: Some fields from single payments do not occcur in a bulk payment element — item shape: {chargeBearer?: "DEBT"|"CRED"|"SHAR"|"SLEV", creditorAccount: record, creditorAddress?: record, creditorAgent?: record, creditorAgentName?: string, creditorId?: string, creditorName: string, creditorNameAndAddress?: string, debtorId?: string, debtorName: string, endToEndIdentification: string, equivalentAmount?: record, exchangeRateInformation?: record, instructedAmount?: record, intermediaryAgent?: string, purposeCode?: "SALA"|"PENS", remittanceInformationStructured?: record, ... (5 more fields)}
  --requested-execution-time: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product)} | format pattern "/v1/{payment_service}/{payment_product}") $auth.query)
  let req_body = {"chargeBearer": $charge_bearer, "creditorAccount": $creditor_account, "creditorAddress": $creditor_address, "creditorAgent": $creditor_agent, "creditorAgentName": $creditor_agent_name, "creditorId": $creditor_id, "creditorName": $creditor_name, "creditorNameAndAddress": $creditor_name_and_address, "debtorAccount": $debtor_account, "debtorAgent": $debtor_agent, "debtorId": $debtor_id, "debtorName": $debtor_name, "endToEndIdentification": $end_to_end_identification, "equivalentAmount": $equivalent_amount, "exchangeRateInformation": $exchange_rate_information, "instructedAmount": $instructed_amount, "intermediaryAgent": $intermediary_agent, "purposeCode": $purpose_code, "remittanceInformationStructured": $remittance_information_structured, "remittanceInformationUnstructured": $remittance_information_unstructured, "requestedExecutionDate": $requested_execution_date, "serviceLevel": $service_level, "transactionCurrency": $transaction_currency, "ultimateCreditor": $ultimate_creditor, "ultimateDebtor": $ultimate_debtor, "dayOfExecution": $day_of_execution, "endDate": $end_date, "executionRule": $execution_rule, "frequency": $frequency, "startDate": $start_date, "batchBookingPreferred": $batch_booking_preferred, "payments": $payments, "requestedExecutionTime": $requested_execution_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "Consent-ID": $consent_id, "PSU-IP-Address": $psu_ip_address, "TPP-Redirect-Preferred": $tpp_redirect_preferred, "TPP-Redirect-URI": $tpp_redirect_uri, "TPP-Nok-Redirect-URI": $tpp_nok_redirect_uri, "TPP-Explicit-Authorisation-Preferred": $tpp_explicit_authorisation_preferred, "TPP-Rejection-NoFunds-Preferred": $tpp_rejection_no_funds_preferred, "TPP-Brand-Logging-Information": $tpp_brand_logging_information, "TPP-Notification-URI": $tpp_notification_uri, "TPP-Notification-Content-Preferred": $tpp_notification_content_preferred, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Payment cancellation request
#
# DELETE /v1/{payment-service}/{payment-product}/{paymentId}
# operationId: cancelPayment
export def "payment-initiation-service-pis cancel" [
  payment_service: string
  payment_product: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification.
  --tpp-explicit-authorisation-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers to start the authorisation process separately, e.g. because of the usage of a signing basket. This preference might be ignored by the ASPSP, if a signing basket is not supported as functionality. If it equals "false" or if the parameter is not used, there is no preference of the TPP. This especially indicates that the TPP assumes a direct authorisation of the transaction in the next step, without using a signing basket.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "TPP-Redirect-Preferred": $tpp_redirect_preferred, "TPP-Nok-Redirect-URI": $tpp_nok_redirect_uri, "TPP-Redirect-URI": $tpp_redirect_uri, "TPP-Explicit-Authorisation-Preferred": $tpp_explicit_authorisation_preferred, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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
  send-delete $req null $insecure $raw $allow_errors $full [202 204]
}

# Get payment information
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}
# operationId: getPaymentInformation
export def "payment-initiation-service-pis get-information" [
  payment_service: string
  payment_product: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Get payment initiation authorisation sub-resources request
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/authorisations
# operationId: getPaymentInitiationAuthorisation
export def "authorisations get-initiation" [
  payment_service: string
  payment_product: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}/authorisations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Start the authorisation process for a payment initiation
#
# POST /v1/{payment-service}/{payment-product}/{paymentId}/authorisations
# operationId: startPaymentAuthorisation
# --psuData shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
export def "authorisations start" [
  payment_service: string
  payment_product: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification.
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}/authorisations") $auth.query)
  let req_body = {"psuData": $psu_data, "authenticationMethodId": $authentication_method_id, "scaAuthenticationData": $sca_authentication_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "TPP-Redirect-Preferred": $tpp_redirect_preferred, "TPP-Redirect-URI": $tpp_redirect_uri, "TPP-Nok-Redirect-URI": $tpp_nok_redirect_uri, "TPP-Notification-URI": $tpp_notification_uri, "TPP-Notification-Content-Preferred": $tpp_notification_content_preferred, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Read the SCA status of the payment authorisation
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/authorisations/{authorisationId}
# operationId: getPaymentInitiationScaStatus
export def "authorisations get-initiation-sca-status" [
  payment_service: string
  payment_product: string
  payment_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  if ($authorisation_id | is-empty) { error make --unspanned { msg: "path parameter 'authorisationId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id), authorisation_id: (encode-path-segment $authorisation_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}/authorisations/{authorisation_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Update PSU data for payment initiation
#
# PUT /v1/{payment-service}/{payment-product}/{paymentId}/authorisations/{authorisationId}
# operationId: updatePaymentPsuData
# --psuData shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
export def "authorisations update-psu-data" [
  payment_service: string
  payment_product: string
  payment_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
  --confirmation-code: string # Confirmation Code as retrieved by the TPP from the redirect based SCA process.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  if ($authorisation_id | is-empty) { error make --unspanned { msg: "path parameter 'authorisationId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id), authorisation_id: (encode-path-segment $authorisation_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}/authorisations/{authorisation_id}") $auth.query)
  let req_body = {"psuData": $psu_data, "authenticationMethodId": $authentication_method_id, "scaAuthenticationData": $sca_authentication_data, "confirmationCode": $confirmation_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Will deliver an array of resource identifications to all generated cancellation authorisation sub-resources
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations
# operationId: getPaymentInitiationCancellationAuthorisationInformation
export def "cancellation-authorisations get-initiation-information" [
  payment_service: string
  payment_product: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}/cancellation-authorisations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Start the authorisation process for the cancellation of the addressed payment
#
# POST /v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations
# operationId: startPaymentInitiationCancellationAuthorisation
# --psuData shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
export def "cancellation-authorisations start-initiation" [
  payment_service: string
  payment_product: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --tpp-redirect-preferred: oneof<nothing, bool> # If it equals "true", the TPP prefers a redirect over an embedded SCA approach. If it equals "false", the TPP prefers not to be redirected for SCA. The ASPSP will then choose between the Embedded or the Decoupled SCA approach, depending on the choice of the SCA procedure by the TPP/PSU. If the parameter is not used, the ASPSP will choose the SCA approach to be applied depending on the SCA method chosen by the TPP/PSU.
  --tpp-redirect-uri: string # URI of the TPP, where the transaction flow shall be redirected to after a Redirect. Mandated for the Redirect SCA Approach, specifically when TPP-Redirect-Preferred equals "true". It is recommended to always use this header field. **Remark for Future:** This field might be changed to mandatory in the next version of the specification.
  --tpp-nok-redirect-uri: string # If this URI is contained, the TPP is asking to redirect the transaction flow to this address instead of the TPP-Redirect-URI in case of a negative result of the redirect SCA method. This might be ignored by the ASPSP.
  --tpp-notification-uri: string # URI for the Endpoint of the TPP-API to which the status of the payment initiation should be sent. This header field may by ignored by the ASPSP. For security reasons, it shall be ensured that the TPP-Notification-URI as introduced above is secured by the TPP eIDAS QWAC used for identification of the TPP. The following applies: URIs which are provided by TPPs in TPP-Notification-URI shall comply with the domain secured by the eIDAS QWAC certificate of the TPP in the field CN or SubjectAltName of the certificate. Please note that in case of example-TPP.com as certificate entry TPP- Notification-URI like www.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications or notifications.example-TPP.com/xs2a-client/v1/ASPSPidentifcation/mytransaction- id/notifications would be compliant. Wildcard definitions shall be taken into account for compliance checks by the ASPSP. ASPSPs may respond with ASPSP-Notification-Support set to false, if the provided URIs do not comply.
  --tpp-notification-content-preferred: string # The string has the form status=X1, ..., Xn where Xi is one of the constants SCA, PROCESS, LAST and where constants are not repeated. The usage of the constants supports the of following semantics: SCA: A notification on every change of the scaStatus attribute for all related authorisation processes is preferred by the TPP. PROCESS: A notification on all changes of consentStatus or transactionStatus attributes is preferred by the TPP. LAST: Only a notification on the last consentStatus or transactionStatus as available in the XS2A interface is preferred by the TPP. This header field may be ignored, if the ASPSP does not support resource notification services for the related TPP.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}/cancellation-authorisations") $auth.query)
  let req_body = {"psuData": $psu_data, "authenticationMethodId": $authentication_method_id, "scaAuthenticationData": $sca_authentication_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "TPP-Redirect-Preferred": $tpp_redirect_preferred, "TPP-Redirect-URI": $tpp_redirect_uri, "TPP-Nok-Redirect-URI": $tpp_nok_redirect_uri, "TPP-Notification-URI": $tpp_notification_uri, "TPP-Notification-Content-Preferred": $tpp_notification_content_preferred, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Read the SCA status of the payment cancellation's authorisation
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations/{authorisationId}
# operationId: getPaymentCancellationScaStatus
export def "cancellation-authorisations get-sca-status" [
  payment_service: string
  payment_product: string
  payment_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  if ($authorisation_id | is-empty) { error make --unspanned { msg: "path parameter 'authorisationId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id), authorisation_id: (encode-path-segment $authorisation_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}/cancellation-authorisations/{authorisation_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Update PSU data for payment initiation cancellation
#
# PUT /v1/{payment-service}/{payment-product}/{paymentId}/cancellation-authorisations/{authorisationId}
# operationId: updatePaymentCancellationPsuData
# --psuData shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
export def "cancellation-authorisations update-psu-data" [
  payment_service: string
  payment_product: string
  payment_id: string
  authorisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-id: string # Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSP's documentation. It might be contained even if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in an preceding AIS service in the same session. In this case the ASPSP might check whether PSU-ID and token match, according to ASPSP documentation. (e.g. PSU-1234)
  --psu-id-type: string # Type of the PSU-ID, needed in scenarios where PSUs have several PSU-IDs as access possibility. In this case, the mean and use are then defined in the ASPSP's documentation.
  --psu-corporate-id: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-corporate-id-type: string # Might be mandated in the ASPSP's documentation. Only used in a corporate context.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
  --psu-data: record # PSU Data for Update PSU authentication. — shape: {additionalEncryptedPassword?: string, additionalPassword?: string, encryptedPassword?: string, password?: string}
  --authentication-method-id: string # An identification provided by the ASPSP for the later identification of the authentication method selection. (e.g. myAuthenticationID)
  --sca-authentication-data: string # SCA authentication data, depending on the chosen authentication method. If the data is binary, then it is base64 encoded.
  --confirmation-code: string # Confirmation Code as retrieved by the TPP from the redirect based SCA process.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  if ($authorisation_id | is-empty) { error make --unspanned { msg: "path parameter 'authorisationId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id), authorisation_id: (encode-path-segment $authorisation_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}/cancellation-authorisations/{authorisation_id}") $auth.query)
  let req_body = {"psuData": $psu_data, "authenticationMethodId": $authentication_method_id, "scaAuthenticationData": $sca_authentication_data, "confirmationCode": $confirmation_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-ID": $psu_id, "PSU-ID-Type": $psu_id_type, "PSU-Corporate-ID": $psu_corporate_id, "PSU-Corporate-ID-Type": $psu_corporate_id_type, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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

# Payment initiation status request
#
# GET /v1/{payment-service}/{payment-product}/{paymentId}/status
# operationId: getPaymentInitiationStatus
export def "status get-initiation" [
  payment_service: string
  payment_product: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID of the request, unique to the call, as determined by the initiating party. (e.g. 99391c7e-ad88-49ec-a2ad-99ddcb1f7721)
  --digest: string # Is contained if and only if the "Signature" element is contained in the header of the request. (e.g. SHA-256=hl1/Eps8BEQW58FJhDApwJXjGY4nr1ArGDHIT25vq6A=)
  --signature: string # A signature of the request by the TPP on application level. This might be mandated by ASPSP. (e.g. keyId="SN=9FA1,CA=CN=D-TRUST%20CA%202-1%202015,O=D-Trust%20GmbH,C=DE",algorithm="rsa-sha256", headers="Digest X-Request-ID PSU-ID TPP-Redirect-URI Date", signature="Base64(RSA-SHA256(signing string))" )
  --tpp-signature-certificate: string # The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.
  --psu-ip-address: string # The forwarded IP Address header field consists of the corresponding http request IP Address field between PSU and TPP. (e.g. 192.168.8.78)
  --psu-ip-port: string # The forwarded IP Port header field consists of the corresponding HTTP request IP Port field between PSU and TPP, if available. (e.g. 1234)
  --psu-accept: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-charset: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-encoding: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-accept-language: string # The forwarded IP Accept header fields consist of the corresponding HTTP request Accept header fields between PSU and TPP, if available.
  --psu-user-agent: string # The forwarded Agent header field of the HTTP request between PSU and TPP, if available.
  --psu-http-method: string@psu-http-method-completer # HTTP method used at the PSU ? TPP interface, if available. Valid values are: * GET * POST * PUT * PATCH * DELETE
  --psu-device-id: string # UUID (Universally Unique Identifier) for a device, which is used by the PSU, if available. UUID identifies either a device or a device dependant application installation. In case of an installation identification this ID needs to be unaltered until removal from device. (e.g. 99435c7e-ad88-49ec-a2ad-99ddcb1f5555)
  --psu-geo-location: string # The forwarded Geo Location of the corresponding http request between PSU and TPP if available. (e.g. GEO:52.506931;13.144558)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_service | is-empty) { error make --unspanned { msg: "path parameter 'payment-service' must be non-empty" } }
  if ($payment_product | is-empty) { error make --unspanned { msg: "path parameter 'payment-product' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_service: (encode-path-segment $payment_service), payment_product: (encode-path-segment $payment_product), payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/{payment_service}/{payment_product}/{payment_id}/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-ID": $x_request_id, "Digest": $digest, "Signature": $signature, "TPP-Signature-Certificate": $tpp_signature_certificate, "PSU-IP-Address": $psu_ip_address, "PSU-IP-Port": $psu_ip_port, "PSU-Accept": $psu_accept, "PSU-Accept-Charset": $psu_accept_charset, "PSU-Accept-Encoding": $psu_accept_encoding, "PSU-Accept-Language": $psu_accept_language, "PSU-User-Agent": $psu_user_agent, "PSU-Http-Method": $psu_http_method, "PSU-Device-ID": $psu_device_id, "PSU-Geo-Location": $psu_geo_location} | compact
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
