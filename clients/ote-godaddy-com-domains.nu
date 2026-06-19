# Auto-generated client for  v1.0.0
# Source: https://api.apis.guru/v2/specs/ote-godaddy.com/domains/1.0.0/openapi.json
# Auth: --token flag or $env._TOKEN

const BASE_URL = "http://localhost//api.ote-godaddy.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o _TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["http://localhost//api.ote-godaddy.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/javascript" "application/json" "application/xml" "text/javascript" "text/xml"] }
def check-type-completer [] { ["FAST" "FULL" "fast" "full"] }
def entity-type-completer [] { ["ABORIGINAL" "ASSOCIATION" "CITIZEN" "CORPORATION" "EDUCATIONAL" "GOVERNMENT" "HOSPITAL" "INDIAN_BAND" "LEGAL_REPRESENTATIVE" "LIBRARY_ARCHIVE_MUSEUM" "MARK_REGISTERED" "MARK_TRADE" "PARTNERSHIP" "POLITICAL_PARTY" "RESIDENT_PERMANENT" "TRUST" "UNION"] }
def country-completer [] { ["AC" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KR" "KV" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "ST" "SV" "SX" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TP" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW"] }
def type-completer [] { ["MASKED" "REDIRECT_PERMANENT" "REDIRECT_TEMPORARY"] }
def status-completer [] { ["ACTIVE" "CANCELLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domains list" } } | get name | first)
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

# Retrieve a list of Domains for the specified Shopper
#
# GET /v1/domains
# operationId: list
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --statuses: list<string> # Only include results with `status` value in the specified set
  --status-groups: list<string> # Only include results with `status` value in any of the specified groups
  --limit: int # Maximum number of domains to return
  --marker: string # Marker Domain to use as the offset in results
  --includes: list<string> # Optional details to be included in the response
  --modified-date: string # Only include results that have been modified since the specified date (format: iso-datetime)
  --x-shopper-id: string # Shopper ID whose domains are to be retrieved
]: nothing -> table<authCode: string, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdAt: string, deletedAt: string, domain: string, domainId: float, expirationProtected: bool, expires: string, exposeWhois: bool, holdRegistrar: bool, locked: bool, nameServers: list<string>, privacy: bool, registrarCreatedAt: string, renewAuto: bool, renewDeadline: string, renewable: bool, status: string, transferAwayEligibleAt: string, transferProtected: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statuses" $statuses "csv") (serialize-qp "statusGroups" $status_groups "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "includes" $includes "csv") (serialize-qp "modifiedDate" $modified_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domains" $qp)
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"statuses": $statuses, "statusGroups": $status_groups, "limit": $limit, "marker": $marker, "includes": $includes, "modifiedDate": $modified_date} | compact), body: null}
}

# Retrieve the legal agreement(s) required to purchase the specified TLD and add-ons
#
# GET /v1/domains/agreements
# operationId: getAgreement
export def "domains-agreements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --tlds: list<string> # list of TLDs whose legal agreements are to be retrieved
  --privacy: oneof<nothing, bool> # Whether or not privacy has been requested
  --for-transfer: oneof<nothing, bool> # Whether or not domain tranfer has been requested
  --x-market-id: string # Unique identifier of the Market used to retrieve/translate Legal Agreements
]: nothing -> table<agreementKey: string, content: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tlds" $tlds "csv") (serialize-qp "privacy" $privacy "scalar") (serialize-qp "forTransfer" $for_transfer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domains/agreements" $qp)
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Market-Id": $x_market_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tlds": $tlds, "privacy": $privacy, "forTransfer": $for_transfer} | compact), body: null}
}

# Determine whether or not the specified domain is available for purchase
#
# GET /v1/domains/available
# operationId: available
export def "domains-available get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --domain: string # Domain name whose availability is to be checked
  --check-type: string@check-type-completer # Optimize for time ('FAST') or accuracy ('FULL') (default: FAST)
  --for-transfer: oneof<nothing, bool> # Whether or not to include domains available for transfer. If set to True, checkType is ignored (default: false)
]: nothing -> record<available: bool, currency: string, definitive: bool, domain: string, period: int, price: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "checkType" $check_type "scalar") (serialize-qp "forTransfer" $for_transfer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domains/available" $qp)
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "checkType": $check_type, "forTransfer": $for_transfer} | compact), body: null}
}

# Determine whether or not the specified domains are available for purchase
#
# POST /v1/domains/available
# operationId: availableBulk
export def "domains-available create-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --check-type: string@check-type-completer # Optimize for time ('FAST') or accuracy ('FULL') (default: FAST)
  --body: list
]: any -> record<domains: table<available: bool, currency: string, definitive: bool, domain: string, period: int, price: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checkType" $check_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domains/available" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"checkType": $check_type} | compact), body: $req_body}
}

# Validate the request body using the Domain Contact Validation Schema for specified domains.
#
# POST /v1/domains/contacts/validate
# operationId: ContactsValidate
# --contactAdmin shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactBilling shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactPresence shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactRegistrant shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactTech shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
export def "domains-contacts-validate validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market-id: string # MarketId in which the request is being made, and for which responses should be localized (format: bcp-47, default: en-US)
  --x-private-label-id: int # PrivateLabelId to operate as, if different from JWT
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-presence: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  domains: list<string> # An array of domain names to be validated against. Alternatively, you can specify the extracted tlds. However, full domain names are required if the tld is `uk`
  --entity-type: string@entity-type-completer # Canadian Presence Requirement (CA)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketId" $market_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domains/contacts/validate" $qp)
  let req_body = {"contactAdmin": $contact_admin, "contactBilling": $contact_billing, "contactPresence": $contact_presence, "contactRegistrant": $contact_registrant, "contactTech": $contact_tech, "domains": $domains, "entityType": $entity_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Private-Label-Id": $x_private_label_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"marketId": $market_id} | compact), body: $req_body}
}

# Purchase and register the specified Domain
#
# POST /v1/domains/purchase
# operationId: purchase
# --consent shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
# --contactAdmin shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactBilling shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactRegistrant shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactTech shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
export def "domains-purchase create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-shopper-id: string # The Shopper for whom the domain should be purchased
  consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  domain: string # For internationalized domain names with non-ascii characters, the domain name is converted to punycode before format and pattern validation rules are checked (format: domain)
  --name-servers: list<string>
  --period: int # format: integer-positive, default: 1
  --privacy: oneof<nothing, bool> # default: false
  --renew-auto: oneof<nothing, bool> # default: true
]: any -> record<currency: string, itemCount: int, orderId: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domains/purchase")
  let req_body = {"consent": $consent, "contactAdmin": $contact_admin, "contactBilling": $contact_billing, "contactRegistrant": $contact_registrant, "contactTech": $contact_tech, "domain": $domain, "nameServers": $name_servers, "period": $period, "privacy": $privacy, "renewAuto": $renew_auto} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve the schema to be submitted when registering a Domain for the specified TLD
#
# GET /v1/domains/purchase/schema/{tld}
# operationId: schema
export def "domains-purchase-schema get" [
  tld: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, models: record, properties: record, required: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tld | is-empty) { error make --unspanned { msg: "path parameter 'tld' must be non-empty" } }
  let full_url = (build-url $base ({tld: (encode-path-segment $tld)} | format pattern "/v1/domains/purchase/schema/{tld}"))
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Validate the request body using the Domain Purchase Schema for the specified TLD
#
# POST /v1/domains/purchase/validate
# operationId: validate
# --consent shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
# --contactAdmin shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactBilling shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactRegistrant shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactTech shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
export def "domains-purchase-validate validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  domain: string # For internationalized domain names with non-ascii characters, the domain name is converted to punycode before format and pattern validation rules are checked (format: domain)
  --name-servers: list<string>
  --period: int # format: integer-positive, default: 1
  --privacy: oneof<nothing, bool> # default: false
  --renew-auto: oneof<nothing, bool> # default: true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domains/purchase/validate")
  let req_body = {"consent": $consent, "contactAdmin": $contact_admin, "contactBilling": $contact_billing, "contactRegistrant": $contact_registrant, "contactTech": $contact_tech, "domain": $domain, "nameServers": $name_servers, "period": $period, "privacy": $privacy, "renewAuto": $renew_auto} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Suggest alternate Domain names based on a seed Domain, a set of keywords, or the shopper's purchase history
#
# GET /v1/domains/suggest
# operationId: suggest
export def "domains-suggest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # Domain name or set of keywords for which alternative domain names will be suggested
  --country: string@country-completer # Two-letter ISO country code to be used as a hint for target region NOTE: These are sample values, there are many more (http://www.iso.org/iso/country_codes.htm) (format: iso-country-code)
  --city: string # Name of city to be used as a hint for target region (format: city-name)
  --sources: list<string> # Sources to be queried CC_TLD - Varies the TLD using Country Codes EXTENSION - Varies the TLD KEYWORD_SPIN - Identifies keywords and then rotates each one PREMIUM - Includes variations with premium prices
  --tlds: list<string> # Top-level domains to be included in suggestions NOTE: These are sample values, there are many more (http://www.godaddy.com/tlds/gtld.aspx#domain_search_form)
  --length-max: int # Maximum length of second-level domain
  --length-min: int # Minimum length of second-level domain
  --limit: int # Maximum number of suggestions to return
  --wait-ms: int # Maximum amount of time, in milliseconds, to wait for responses If elapses, return the results compiled up to that point (format: integer-positive, default: 1000)
  --x-shopper-id: string # Shopper ID for which the suggestions are being generated
]: nothing -> table<domain: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "sources" $sources "csv") (serialize-qp "tlds" $tlds "csv") (serialize-qp "lengthMax" $length_max "scalar") (serialize-qp "lengthMin" $length_min "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "waitMs" $wait_ms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domains/suggest" $qp)
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "country": $country, "city": $city, "sources": $sources, "tlds": $tlds, "lengthMax": $length_max, "lengthMin": $length_min, "limit": $limit, "waitMs": $wait_ms} | compact), body: null}
}

# Retrieves a list of TLDs supported and enabled for sale
#
# GET /v1/domains/tlds
# operationId: tlds
export def "domains-tlds get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domains/tlds")
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel a purchased domain
#
# DELETE /v1/domains/{domain}
# operationId: cancel
export def "domains cancel" [
  domain: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve details for the specified Domain
#
# GET /v1/domains/{domain}
# operationId: get
export def "domains get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-shopper-id: string # Shopper ID expected to own the specified domain
]: nothing -> record<authCode: string, contactAdmin: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdAt: string, deletedAt: string, domain: string, domainId: float, expirationProtected: bool, expires: string, exposeWhois: bool, holdRegistrar: bool, locked: bool, nameServers: list<string>, privacy: bool, registrarCreatedAt: string, renewAuto: bool, renewDeadline: string, status: string, subaccountId: string, transferAwayEligibleAt: string, transferProtected: bool, verifications: record<domainName: record<status: string>, realName: record<status: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}"))
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update details for the specified Domain
#
# PATCH /v1/domains/{domain}
# operationId: update
# --consent shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
export def "domains update" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper for whom Domain is to be updated. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
  --expose-whois: oneof<nothing, bool> # Whether or not the domain contact details should be shown in the WHOIS
  --locked: oneof<nothing, bool> # Whether or not the domain should be locked to prevent transfers
  --name-servers: list # Fully-qualified domain names for Name Servers to associate with the domain
  --renew-auto: oneof<nothing, bool> # Whether or not the domain should be configured to automatically renew
  --subaccount-id: string # Reseller subaccount shopperid who can manage the domain
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}"))
  let req_body = {"consent": $consent, "exposeWhois": $expose_whois, "locked": $locked, "nameServers": $name_servers, "renewAuto": $renew_auto, "subaccountId": $subaccount_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update domain
#
# PATCH /v1/domains/{domain}/contacts
# operationId: updateContacts
# --contactAdmin shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactBilling shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactRegistrant shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactTech shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
export def "domains-contacts update" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper for whom domain contacts are to be updated. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  contact_registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}/contacts"))
  let req_body = {"contactAdmin": $contact_admin, "contactBilling": $contact_billing, "contactRegistrant": $contact_registrant, "contactTech": $contact_tech} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Submit a privacy cancellation request for the given domain
#
# DELETE /v1/domains/{domain}/privacy
# operationId: cancelPrivacy
export def "domains-privacy cancel" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID of the owner of the domain
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}/privacy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Purchase privacy for a specified domain
#
# POST /v1/domains/{domain}/privacy/purchase
# operationId: purchasePrivacy
# --consent shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
export def "domains-privacy-purchase create" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-shopper-id: string # Shopper ID of the owner of the domain
  consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
]: any -> record<currency: string, itemCount: int, orderId: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}/privacy/purchase"))
  let req_body = {"consent": $consent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add the specified DNS Records to the specified Domain
#
# PATCH /v1/domains/{domain}/records
# operationId: recordAdd
export def "domains-records create" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}/records"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace all DNS Records for the specified Domain
#
# PUT /v1/domains/{domain}/records
# operationId: recordReplace
export def "domains-records update-by-domain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}/records"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace all DNS Records for the specified Domain with the specified Type
#
# PUT /v1/domains/{domain}/records/{type}
# operationId: recordReplaceType
export def "domains-records update-by-domain-type" [
  domain: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain), type: (encode-path-segment $type)} | format pattern "/v1/domains/{domain}/records/{type}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete all DNS Records for the specified Domain with the specified Type and Name
#
# DELETE /v1/domains/{domain}/records/{type}/{name}
# operationId: recordDeleteTypeName
export def "domains-records delete" [
  domain: string
  type: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain), type: (encode-path-segment $type), name: (encode-path-segment $name)} | format pattern "/v1/domains/{domain}/records/{type}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve DNS Records for the specified Domain, optionally with the specified Type and/or Name
#
# GET /v1/domains/{domain}/records/{type}/{name}
# operationId: recordGet
export def "domains-records get" [
  domain: string
  type: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # Number of results to skip for pagination
  --limit: int # Maximum number of items to return
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
]: nothing -> table<data: string, name: string, port: int, priority: int, protocol: string, service: string, ttl: int, type: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain: (encode-path-segment $domain), type: (encode-path-segment $type), name: (encode-path-segment $name)} | format pattern "/v1/domains/{domain}/records/{type}/{name}") $qp)
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "limit": $limit} | compact), body: null}
}

# Replace all DNS Records for the specified Domain with the specified Type and Name
#
# PUT /v1/domains/{domain}/records/{type}/{name}
# operationId: recordReplaceTypeName
export def "domains-records update-by-domain-type-name" [
  domain: string
  type: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain), type: (encode-path-segment $type), name: (encode-path-segment $name)} | format pattern "/v1/domains/{domain}/records/{type}/{name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Renew the specified Domain
#
# POST /v1/domains/{domain}/renew
# operationId: renew
export def "domains-renew create" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-shopper-id: string # Shopper for whom Domain is to be renewed. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --period: int # Number of years to extend the Domain. Must not exceed maximum for TLD. When omitted, defaults to `period` specified during original purchase (format: integer-positive)
]: any -> record<currency: string, itemCount: int, orderId: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}/renew"))
  let req_body = {"period": $period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Purchase and start or restart transfer process
#
# POST /v1/domains/{domain}/transfer
# operationId: transferIn
# --consent shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
# --contactAdmin shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactBilling shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactRegistrant shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
# --contactTech shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
export def "domains-transfer create" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-shopper-id: string # The Shopper to whom the domain should be transfered
  auth_code: string # Authorization code from registrar for transferring a domain
  consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --period: int # Can be more than 1 but no more than 10 years total including current registration length (format: integer-positive, default: 1)
  --privacy: oneof<nothing, bool> # Whether or not privacy has been requested (default: false)
  --renew-auto: oneof<nothing, bool> # Whether or not the domain should be configured to automatically renew (default: true)
]: any -> record<currency: string, itemCount: int, orderId: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}/transfer"))
  let req_body = {"authCode": $auth_code, "consent": $consent, "contactAdmin": $contact_admin, "contactBilling": $contact_billing, "contactRegistrant": $contact_registrant, "contactTech": $contact_tech, "period": $period, "privacy": $privacy, "renewAuto": $renew_auto} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/javascript")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Re-send Contact E-mail Verification for specified Domain
#
# POST /v1/domains/{domain}/verifyRegistrantEmail
# operationId: verifyEmail
export def "domains-verify-registrant-email verify" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper for whom domain contact e-mail should be verified. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v1/domains/{domain}/verifyRegistrantEmail"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Shopper-Id": $x_shopper_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Submit a forwarding cancellation request for the given fqdn
#
# DELETE /v2/customers/{customerId}/domains/forwards/{fqdn}
# operationId: domainsForwardsDelete
export def "customers-domains-forwards delete" [
  customer_id: string
  fqdn: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($fqdn | is-empty) { error make --unspanned { msg: "path parameter 'fqdn' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), fqdn: (encode-path-segment $fqdn)} | format pattern "/v2/customers/{customer_id}/domains/forwards/{fqdn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve the forwarding information for the given fqdn
#
# GET /v2/customers/{customerId}/domains/forwards/{fqdn}
# operationId: domainsForwardsGet
export def "customers-domains-forwards get" [
  customer_id: string
  fqdn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-subs: oneof<nothing, bool> # Optionally include all sub domains if the fqdn specified is a domain and not a sub domain.
]: nothing -> table<fqdn: string, mask: record<description: string, keywords: string, title: string>, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($fqdn | is-empty) { error make --unspanned { msg: "path parameter 'fqdn' must be non-empty" } }
  let qp = [(serialize-qp "includeSubs" $include_subs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), fqdn: (encode-path-segment $fqdn)} | format pattern "/v2/customers/{customer_id}/domains/forwards/{fqdn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeSubs": $include_subs} | compact), body: null}
}

# Create a new forwarding configuration for the given FQDN
#
# POST /v2/customers/{customerId}/domains/forwards/{fqdn}
# operationId: domainsForwardsPost
# --mask shape: {description?: string, keywords?: string, title?: string}
export def "customers-domains-forwards create" [
  customer_id: string
  fqdn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mask: any # shape: {description?: string, keywords?: string, title?: string}
  type: string@type-completer # The type of fowarding to implementMASKED - Prevents the forwarded domain or subdomain URL from displaying in the browser's address bar.REDIRECT_PERMANENT* - Redirects to the url you specified in the forwardTo field using a `301 Moved Permanently` HTTP response. The HTTP 301 response code tells user-agents (including search engines) that the location has permanently moved.REDIRECT_TEMPORARY - Redirects to the url you specified in the forwardTo field using a `302 Found` HTTP response. The HTTP 302 response code tells user-agents (including search engines) that the location has temporarily moved. (default: REDIRECT_PERMANENT)
  url: string # Forwards http(s) traffic to this destination url (ex. http://www.somedomain.com/) (format: url)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($fqdn | is-empty) { error make --unspanned { msg: "path parameter 'fqdn' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), fqdn: (encode-path-segment $fqdn)} | format pattern "/v2/customers/{customer_id}/domains/forwards/{fqdn}"))
  let req_body = {"mask": $mask, "type": $type, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Modify the forwarding information for the given fqdn
#
# PUT /v2/customers/{customerId}/domains/forwards/{fqdn}
# operationId: domainsForwardsPut
# --mask shape: {description?: string, keywords?: string, title?: string}
export def "customers-domains-forwards update" [
  customer_id: string
  fqdn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mask: any # shape: {description?: string, keywords?: string, title?: string}
  type: string@type-completer # The type of fowarding to implementMASKED - Prevents the forwarded domain or subdomain URL from displaying in the browser's address bar.REDIRECT_PERMANENT* - Redirects to the url you specified in the forwardTo field using a `301 Moved Permanently` HTTP response. The HTTP 301 response code tells user-agents (including search engines) that the location has permanently moved.REDIRECT_TEMPORARY - Redirects to the url you specified in the forwardTo field using a `302 Found` HTTP response. The HTTP 302 response code tells user-agents (including search engines) that the location has temporarily moved. (default: REDIRECT_PERMANENT)
  url: string # Forwards http(s) traffic to this destination url (ex. http://www.somedomain.com/) (format: url)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($fqdn | is-empty) { error make --unspanned { msg: "path parameter 'fqdn' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), fqdn: (encode-path-segment $fqdn)} | format pattern "/v2/customers/{customer_id}/domains/forwards/{fqdn}"))
  let req_body = {"mask": $mask, "type": $type, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve the next domain notification
#
# GET /v2/customers/{customerId}/domains/notifications
export def "customers-domains-notifications get" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> record<addedAt: string, metadata: record, notificationId: string, requestId: string, resource: string, resourceType: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v2/customers/{customer_id}/domains/notifications"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of notification types that are opted in
#
# GET /v2/customers/{customerId}/domains/notifications/optIn
export def "customers-domains-notifications-opt-in get" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> table<addedAt: string, metadata: record, notificationId: string, requestId: string, resource: string, resourceType: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v2/customers/{customer_id}/domains/notifications/optIn"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Opt in to recieve notifications for the submitted notification types
#
# PUT /v2/customers/{customerId}/domains/notifications/optIn
export def "customers-domains-notifications-opt-in update" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --types: list<string> # The notification types that should be opted in
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "types" $types "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v2/customers/{customer_id}/domains/notifications/optIn") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"types": $types} | compact), body: null}
}

# Retrieve the schema for the notification data for the specified notification type
#
# GET /v2/customers/{customerId}/domains/notifications/schemas/{type}
export def "customers-domains-notifications-schemas get" [
  customer_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> record<id: string, models: record, properties: record, required: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), type: (encode-path-segment $type)} | format pattern "/v2/customers/{customer_id}/domains/notifications/schemas/{type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Acknowledge a domain notification
#
# POST /v2/customers/{customerId}/domains/notifications/{notificationId}/acknowledge
export def "customers-domains-notifications-acknowledge create" [
  customer_id: string
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notificationId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), notification_id: (encode-path-segment $notification_id)} | format pattern "/v2/customers/{customer_id}/domains/notifications/{notification_id}/acknowledge"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve details for the specified Domain
#
# GET /v2/customers/{customerId}/domains/{domain}
export def "customers-domains get" [
  customer_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list<string> # Optional details to be included in the response
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> record<actions: table<completedAt: string, createdAt: string, modifiedAt: string, origination: string, reason: record, requestId: string, startedAt: string, status: string, type: string>, authCode: string, contacts: record<admin: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>, billing: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>, registrant: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>, tech: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>>, createdAt: string, deletedAt: string, dnssecRecords: table<algorithm: string, digest: string, digestType: string, flags: string, keyTag: int, maxSignatureLife: int, publicKey: string>, domain: string, domainId: string, expirationProtected: bool, expiresAt: string, holdRegistrar: bool, hostnames: list<string>, locked: bool, modifiedAt: string, nameServers: list<string>, privacy: bool, registrarCreatedAt: string, registryStatusCodes: list<string>, renewAuto: bool, renewDeadline: string, renewal: record<currency: string, price: int, renewable: bool>, status: string, subaccountId: string, transferAwayEligibleAt: string, transferProtected: bool, verifications: record<domainName: string, icann: string, realName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "includes" $includes "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), domain: (encode-path-segment $domain)} | format pattern "/v2/customers/{customer_id}/domains/{domain}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includes": $includes} | compact), body: null}
}

# Retrieves a list of the most recent actions for the specified domain
#
# GET /v2/customers/{customerId}/domains/{domain}/actions
export def "customers-domains-actions list" [
  customer_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> table<completedAt: string, createdAt: string, modifiedAt: string, origination: string, reason: record<code: string, fields: list, message: string>, requestId: string, startedAt: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), domain: (encode-path-segment $domain)} | format pattern "/v2/customers/{customer_id}/domains/{domain}/actions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel the most recent user action for the specified domain
#
# DELETE /v2/customers/{customerId}/domains/{domain}/actions/{type}
export def "customers-domains-actions delete" [
  customer_id: string
  domain: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), domain: (encode-path-segment $domain), type: (encode-path-segment $type)} | format pattern "/v2/customers/{customer_id}/domains/{domain}/actions/{type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the most recent action for the specified domain
#
# GET /v2/customers/{customerId}/domains/{domain}/actions/{type}
export def "customers-domains-actions get" [
  customer_id: string
  domain: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> record<completedAt: string, createdAt: string, modifiedAt: string, origination: string, reason: record<code: string, fields: list<record>, message: string>, requestId: string, startedAt: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), domain: (encode-path-segment $domain), type: (encode-path-segment $type)} | format pattern "/v2/customers/{customer_id}/domains/{domain}/actions/{type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Purchase a restore for the given domain to bring it out of redemption
#
# POST /v2/customers/{customerId}/domains/{domain}/redeem
# --consent shape: {agreedAt: string, agreedBy: string, currency: string, fee: int, price: int}
export def "customers-domains-redeem create" [
  customer_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
  consent: any # shape: {agreedAt: string, agreedBy: string, currency: string, fee: int, price: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), domain: (encode-path-segment $domain)} | format pattern "/v2/customers/{customer_id}/domains/{domain}/redeem"))
  let req_body = {"consent": $consent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Initiate transfer out to another registrar for a .uk domain.
#
# POST /v2/customers/{customerId}/domains/{domain}/transferOut
export def "customers-domains-transfer-out create" [
  customer_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --registrar: string # Registrar tag to push transfer to
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "registrar" $registrar "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), domain: (encode-path-segment $domain)} | format pattern "/v2/customers/{customer_id}/domains/{domain}/transferOut") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"registrar": $registrar} | compact), body: null}
}

# Retrieve a list of upcoming system Maintenances
#
# GET /v2/domains/maintenances
export def "domains-maintenances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Only include results with the selected `status` value. Returns all results if omittedACTIVE - The upcoming maintenance is active.CANCELLED - The upcoming maintenance has been cancelled.
  --modified-at-after: string # Only include results with `modifiedAt` after the supplied date (format: iso-datetime)
  --starts-at-after: string # Only include results with `startsAt` after the supplied date (format: iso-datetime)
  --limit: int # Maximum number of results to return (default: 100)
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> record<createdAt: string, endsAt: string, environment: string, maintenanceId: string, modifiedAt: string, reason: string, startsAt: string, status: string, summary: string, tlds: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "modifiedAtAfter" $modified_at_after "scalar") (serialize-qp "startsAtAfter" $starts_at_after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/domains/maintenances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"status": $status, "modifiedAtAfter": $modified_at_after, "startsAtAfter": $starts_at_after, "limit": $limit} | compact), body: null}
}

# Retrieve the details for an upcoming system Maintenances
#
# GET /v2/domains/maintenances/{maintenanceId}
export def "domains-maintenances get" [
  maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> record<createdAt: string, endsAt: string, environment: string, maintenanceId: string, modifiedAt: string, reason: string, startsAt: string, status: string, summary: string, systems: table<impact: list, name: string>, tlds: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($maintenance_id | is-empty) { error make --unspanned { msg: "path parameter 'maintenanceId' must be non-empty" } }
  let full_url = (build-url $base ({maintenance_id: (encode-path-segment $maintenance_id)} | format pattern "/v2/domains/maintenances/{maintenance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
