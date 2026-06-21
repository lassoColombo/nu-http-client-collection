# Auto-generated client for Storecove API v2.0.1
# Source: https://api.apis.guru/v2/specs/storecove.com/2.0.1/openapi.json
# Auth: --token flag or $env.STORECOVE_API_TOKEN

const BASE_URL = "https://api.storecove.com/api/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STORECOVE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.storecove.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def mode-completer [] { ["direct"] }
def country-completer [] { ["AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XI" "YE" "YT" "ZA" "ZM" "ZW"] }
def package-version-completer [] { ["aunz" "peppol_bis_v3" "sg"] }
def packaging-completer [] { ["ubl"] }
def parse-strategy-completer [] { ["rfc822"] }
def syntax-completer [] { ["json" "original"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "discovery-exists create" } } | get name | first)
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

# Discover Network Participant Existence
#
# POST /discovery/exists
# operationId: discovery_exists
export def "discovery-exists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-types: list<string> # An array of document types to discover. The default is '["invoice", "creditnote"]'. This is ignored when only checking existence.
  identifier: string # The actual identifier.
  --meta-scheme: string # The meta scheme of the identifier. For Peppol this is always 'iso6523-actorid-upis'. (default: iso6523-actorid-upis)
  --network: string # The network to check. Currently only 'peppol' is supported. (default: peppol)
  scheme: string # The scheme of the identifier. See <<_receiver_identifiers_list>> for a list.
]: any -> record<code: string, email: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/discovery/exists")
  let req_body = {"documentTypes": $document_types, "identifier": $identifier, "metaScheme": $meta_scheme, "network": $network, "scheme": $scheme} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Discover Country Identifiers ** EXPERIMENTAL
#
# GET /discovery/identifiers
# operationId: discovery_identifiers
export def "discovery-identifiers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countries: table<country: string, receiver: record, region: string, sender: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/discovery/identifiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Disover Network Participant
#
# POST /discovery/receives
# operationId: discovery_receives
export def "discovery-receives create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-types: list<string> # An array of document types to discover. The default is '["invoice", "creditnote"]'. This is ignored when only checking existence.
  identifier: string # The actual identifier.
  --meta-scheme: string # The meta scheme of the identifier. For Peppol this is always 'iso6523-actorid-upis'. (default: iso6523-actorid-upis)
  --network: string # The network to check. Currently only 'peppol' is supported. (default: peppol)
  scheme: string # The scheme of the identifier. See <<_receiver_identifiers_list>> for a list.
]: any -> record<code: string, email: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/discovery/receives")
  let req_body = {"documentTypes": $document_types, "identifier": $identifier, "metaScheme": $meta_scheme, "network": $network, "scheme": $scheme} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Submit a new document.
#
# POST /document_submissions
# operationId: create_document_submission
# --attachments item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
# --document shape: {documentType: "invoice"|"invoice_response"|"order", invoice?: record, invoiceResponse?: record, order?: record, rawDocumentData?: record}
# --routing shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list<string>}
export def "document-submissions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # DEPRECATED. Use the attachments array inside the 'document' property. An array of attachments. You may provide up to 10 attchments, but the total size must not exceed 10MB after Base64 encoding. — item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
  --create-primary-image: oneof<nothing, bool> # DEPRECATED. In the future we will no longer support creating PDF invoices. Whether or not to create a primary image (PDF) if one is not provided. For customers who started from December 1st 2022, the default is false. For customers who started before that, the default is true.
  --document: record # The document to send. — shape: {documentType: "invoice"|"invoice_response"|"order", invoice?: record, invoiceResponse?: record, order?: record, rawDocumentData?: record}
  --idempotency-guid: string # A guid that you generated for this DocumentSubmission to achieve idempotency. If you submit multiple documents with the same idempotencyGuid, only the first one will be processed and any subsequent ones will trigger an HTTP 422 Unprocessable Entity response.
  --legal-entity-id: int # The id of the LegalEntity this document should be sent on behalf of. Either legalEntityId or receiveGuid is mandatory.
  --receive-guid: string # The GUID that was in the received_document webhook. Either legalEntityId or receiveGuid is mandatory. This field is used for sending response documents, such as InvoiceReponse and OrderResponse.
  --routing: record # The different ways to send the invoice to the recipient. The publicIdentifiers are used to send via the Peppol network, if the recipient is not registered on the Peppol network, the invoice will be sent to the email addresses in the emails property. This property is only mandatory when sending the invoice data using the <<_openapi_invoice>> property, not when sending using the <<_openapi_invoicedata>> property, in which case this information will be extracted from the <<_openapi_invoicedata>> object. If you do specify an <<_openapi_invoicerecipient>> object and an <<_openapi_invoicedata>> object, the data from the two will be merged. — shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list<string>}
]: any -> record<guid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document_submissions")
  let req_body = {"attachments": $attachments, "createPrimaryImage": $create_primary_image, "document": $document, "idempotencyGuid": $idempotency_guid, "legalEntityId": $legal_entity_id, "receiveGuid": $receive_guid, "routing": $routing} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get DocumentSubmission Evidence
#
# GET /document_submissions/{guid}/evidence/{evidence_type}
# operationId: show_document_submission_evidence
export def "document-submissions-evidence get-show" [
  guid: string
  evidence_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<documents: table<document: string, expires_at: string, mime_type: string>, evidence: record<message_id: string, receiving_accesspoint: string, remote_mta_ip: string, reporting_mta: string, smtp_response: string, timestamp: string, transmission_id: string, xml: string>, network: string, receiver: string, sender: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($guid | is-empty) { error make --unspanned { msg: "path parameter 'guid' must be non-empty" } }
  if ($evidence_type | is-empty) { error make --unspanned { msg: "path parameter 'evidence_type' must be non-empty" } }
  let full_url = (build-url $base ({guid: (encode-path-segment $guid), evidence_type: (encode-path-segment $evidence_type)} | format pattern "/document_submissions/{guid}/evidence/{evidence_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Submit a new invoice
#
# POST /invoice_submissions
# operationId: create_invoice_submission
# --attachments item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
# --invoice shape: {accountingCost?: string, accountingCurrencyTaxAmount?: float, ... (42 more fields)}
# --invoiceData shape: {conversionStrategy?: "ubl"|"cii"|"idoc", document?: string}
# --invoiceRecipient shape: {emails?: list<string>, publicIdentifiers?: list}
# --routing shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list<string>}
export def "invoice-submissions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # An array of attachments. You may provide up to 10 attchments, but the total size must not exceed 10MB after Base64 encoding. — item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
  --create-primary-image: oneof<nothing, bool> # DEPRECATED. In the future we will no longer support creating PDF invoices. Whether or not to create a primary image (PDF) if one is not provided. For customers who started from December 1st 2022, the default is false. For customers who started before that, the default is true.
  --document: string # DEPRECATED. Use attachments.
  --document-url: string # DEPRECATED. Use attachments. (format: uri)
  --idempotency-guid: string # A guid that you generated for this InvoiceSubmission to achieve idempotency. If you submit multiple documents with the same idempotencyGuid, only the first one will be processed.
  --invoice: record # The invoice to send. Provide either invoice, or invoiceData, but not both. — shape: {accountingCost?: string, accountingCurrencyTaxAmount?: float, ... (42 more fields)}
  --invoice-data: record # The invoice to send, in base64 encoded format. Provide either invoice, or invoiceData, but not both. — shape: {conversionStrategy?: "ubl"|"cii"|"idoc", document?: string}
  --invoice-recipient: record # The different ways to send the invoice to the recipient. The publicIdentifiers are used to send via the Peppol network, if the recipient is not registered on the Peppol network, the invoice will be sent to the email addresses in the emails property. This property is only mandatory when sending the invoice data using the <<_openapi_invoice>> property, not when sending using the <<_openapi_invoicedata>> property, in which case this information will be extracted from the <<_openapi_invoicedata>> object. If you do specify an <<_openapi_invoicerecipient>> object and an <<_openapi_invoicedata>> object, the data from the two will be merged. — shape: {emails?: list<string>, publicIdentifiers?: list}
  --legal-entity-id: int # The id of the LegalEntity this invoice should be sent for.
  --legal-supplier-id: int # DEPRECATED. Use legalEntityId
  --mode: string@mode-completer # DEPRECATED.
  --routing: record # The different ways to send the invoice to the recipient. The publicIdentifiers are used to send via the Peppol network, if the recipient is not registered on the Peppol network, the invoice will be sent to the email addresses in the emails property. This property is only mandatory when sending the invoice data using the <<_openapi_invoice>> property, not when sending using the <<_openapi_invoicedata>> property, in which case this information will be extracted from the <<_openapi_invoicedata>> object. If you do specify an <<_openapi_invoicerecipient>> object and an <<_openapi_invoicedata>> object, the data from the two will be merged. — shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list<string>}
  --supplier-id: int # DEPRECATED.
]: any -> record<guid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoice_submissions")
  let req_body = {"attachments": $attachments, "createPrimaryImage": $create_primary_image, "document": $document, "documentUrl": $document_url, "idempotencyGuid": $idempotency_guid, "invoice": $invoice, "invoiceData": $invoice_data, "invoiceRecipient": $invoice_recipient, "legalEntityId": $legal_entity_id, "legalSupplierId": $legal_supplier_id, "mode": $mode, "routing": $routing, "supplierId": $supplier_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DEPRECATED. Preflight an invoice recipient
#
# POST /invoice_submissions/preflight
# operationId: preflight_invoice_recipient
# --publicIdentifiers item shape: {id: string, scheme: string}
export def "invoice-submissions-preflight create-recipient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-identifiers: list # A list of public identifiers that uniquely identify this customer. — item shape: {id: string, scheme: string}
]: any -> record<code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoice_submissions/preflight")
  let req_body = {"publicIdentifiers": $public_identifiers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DEPRECATED. Get InvoiceSubmission Evidence
#
# GET /invoice_submissions/{guid}/evidence
# operationId: show_invoice_submission_evidence
export def "invoice-submissions-evidence get-show" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: table<receiver_response: string, transmission_datetime: string, transmission_result: string, transmission_type: string, transmitted_document: string>, guid: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($guid | is-empty) { error make --unspanned { msg: "path parameter 'guid' must be non-empty" } }
  let full_url = (build-url $base ({guid: (encode-path-segment $guid)} | format pattern "/invoice_submissions/{guid}/evidence"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new LegalEntity
#
# POST /legal_entities
# operationId: create_legal_entity
# --rea shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", ... (1 more fields)}
export def "legal-entities create-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertisements: list<string> # A list of document types to advertise. Use if this LegalEntity needs the ability to receive more than only invoice documents. (default: [invoice])
  city: string # The city.
  country: string@country-completer # An ISO 3166-1 alpha-2 country code.
  --county: string # County, if applicable
  line1: string # The first address line.
  --line2: string # The second address line, if applicable
  party_name: string # The name of the company.
  --public: oneof<nothing, bool> # Whether or not this LegalEntity is public. Public means it will be entered into the PEPPOL directory at https://directory.peppol.eu/ (default: true)
  --rea: any # shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", ... (1 more fields)}
  --tenant-id: string # The id of the tenant, to be used in case of single-tenant solutions that share webhook URLs. This property will included in webhook events.
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  zip: string # The zipcode.
]: any -> record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legal_entities")
  let req_body = {"advertisements": $advertisements, "city": $city, "country": $country, "county": $county, "line1": $line1, "line2": $line2, "party_name": $party_name, "public": $public, "rea": $rea, "tenant_id": $tenant_id, "third_party_password": $third_party_password, "third_party_username": $third_party_username, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete LegalEntity
#
# DELETE /legal_entities/{id}
# operationId: delete_legal_entity
export def "legal-entities delete-entity" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legal_entities/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get LegalEntity
#
# GET /legal_entities/{id}
# operationId: get_legal_entity
export def "legal-entities get-entity" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legal_entities/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update LegalEntity
#
# PATCH /legal_entities/{id}
# operationId: update_legal_entity
# --rea shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", ... (1 more fields)}
export def "legal-entities update-entity" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertisements: list<string> # A list of document types to advertise. Use if this LegalEntity needs the ability to receive more than only invoice documents. (default: [invoice])
  --city: string # The city.
  --country: string@country-completer # An ISO 3166-1 alpha-2 country code.
  --county: string # County, if applicable
  --body-id: int # The Storecove assigned id for the LegalEntity. (format: int64)
  --line1: string # The first address line.
  --line2: string # The second address line, if applicable
  --party-name: string # The name of the company.
  --public: oneof<nothing, bool> # Whether or not this LegalEntity is public. Public means it will be listed in the PEPPOL directory at https://directory.peppol.eu/ which is normally what you want. If you have a good reason to not want the LegalEntity listed, provide false. This property is ignored when for country SG, where it is always true. (default: true)
  --rea: any # shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", ... (1 more fields)}
  --smart-inbox: string # DEPRECATED. Use the <<_openapi_receiveddocuments_resource>> endpoint. The email address of the Smart Inbox for this LegalEntity.
  --tenant-id: string # The id of the tenant, to be used in case of multi-tenant solutions. This property will included in webhook events.
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  --zip: string # The zipcode.
]: any -> record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legal_entities/{id}"))
  let req_body = {"advertisements": $advertisements, "city": $city, "country": $country, "county": $county, "id": $body_id, "line1": $line1, "line2": $line2, "party_name": $party_name, "public": $public, "rea": $rea, "smart_inbox": $smart_inbox, "tenant_id": $tenant_id, "third_party_password": $third_party_password, "third_party_username": $third_party_username, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a new AdditionalTaxIdentifier
#
# POST /legal_entities/{legal_entity_id}/additional_tax_identifiers
# operationId: create_additional_tax_identifier
export def "legal-entities-additional-tax-identifiers create" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string # The ISO3166 country code to use this identifier for in case of consumerTaxMode.
  --county: string # The county/state inside the country code to use this identifier for in case of consumerTaxMode. Leave empty to create an additional tax identifier for the entire country. For India, use the two last characters of ISO 3166-2:IN (https://en.wikipedia.org/wiki/States_and_union_territories_of_India).
  identifier: string # The identifier.
  scheme: string # The scheme of the identifier.
  superscheme: string # The superscheme of the identifier. Should always be "iso6523-actorid-upis".
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
]: any -> record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id)} | format pattern "/legal_entities/{legal_entity_id}/additional_tax_identifiers"))
  let req_body = {"country": $country, "county": $county, "identifier": $identifier, "scheme": $scheme, "superscheme": $superscheme, "third_party_password": $third_party_password, "third_party_username": $third_party_username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete AdditionalTaxIdentifier
#
# DELETE /legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}
# operationId: delete_additional_tax_identifier
export def "legal-entities-additional-tax-identifiers delete" [
  legal_entity_id: int
  id: int
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
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id), id: (encode-path-segment $id)} | format pattern "/legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get AdditionalTaxIdentifier
#
# GET /legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}
# operationId: get_additional_tax_identifier
export def "legal-entities-additional-tax-identifiers get" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id), id: (encode-path-segment $id)} | format pattern "/legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update AdditionalTaxIdentifier
#
# PATCH /legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}
# operationId: update_additional_tax_identifier
export def "legal-entities-additional-tax-identifiers update" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string # The identifier.
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
]: any -> record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id), id: (encode-path-segment $id)} | format pattern "/legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}"))
  let req_body = {"identifier": $identifier, "third_party_password": $third_party_password, "third_party_username": $third_party_username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a new Administration
#
# POST /legal_entities/{legal_entity_id}/administrations
# operationId: create_administration
export def "legal-entities-administrations create" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address to send the received document to
  --body-legal-entity-id: int # The LegalEntity the Administration belongs to. (format: int64)
  --package-version: string@package-version-completer # The version of the package. (default: peppol_bis_v3)
  --packaging: string@packaging-completer # How to package the purchase invoice. (default: ubl)
  --sender-email-identity-id: int # The id of the SenderEmailIdentity. If not provided, the Storecove default sender will be used (format: int64)
]: any -> record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id)} | format pattern "/legal_entities/{legal_entity_id}/administrations"))
  let req_body = {"email": $email, "legal_entity_id": $body_legal_entity_id, "package_version": $package_version, "packaging": $packaging, "sender_email_identity_id": $sender_email_identity_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Administration
#
# DELETE /legal_entities/{legal_entity_id}/administrations/{id}
# operationId: delete_administration
export def "legal-entities-administrations delete" [
  legal_entity_id: int
  id: int
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
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id), id: (encode-path-segment $id)} | format pattern "/legal_entities/{legal_entity_id}/administrations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Administration
#
# GET /legal_entities/{legal_entity_id}/administrations/{id}
# operationId: get_administration
export def "legal-entities-administrations get" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id), id: (encode-path-segment $id)} | format pattern "/legal_entities/{legal_entity_id}/administrations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Administration
#
# PATCH /legal_entities/{legal_entity_id}/administrations/{id}
# operationId: update_administration
export def "legal-entities-administrations update" [
  legal_entity_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address to send the received document to
  --package-version: string@package-version-completer # The version of the package.
  --packaging: string@packaging-completer # How to package the purchase invoice.
  --sender-email-identity-id: int # The id of the SenderEmailIdentity. If not provided, the Storecove default sender will be used (format: int64)
]: any -> record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id), id: (encode-path-segment $id)} | format pattern "/legal_entities/{legal_entity_id}/administrations/{id}"))
  let req_body = {"email": $email, "package_version": $package_version, "packaging": $packaging, "sender_email_identity_id": $sender_email_identity_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a new PeppolIdentifier
#
# POST /legal_entities/{legal_entity_id}/peppol_identifiers
# operationId: create_peppol_identifier
# --corppass shape: {client_redirect_fail_url?: string, client_redirect_success_url?: string, enabled?: bool, flow_type: "corppass_flow_redirect"|"corppass_flow_email", signer_email?: string, signer_name?: string, simulate_corppass?: bool}
export def "legal-entities-peppol-identifiers create" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --corppass: any # shape: {client_redirect_fail_url?: string, client_redirect_success_url?: string, enabled?: bool, flow_type: "corppass_flow_redirect"|"corppass_flow_email", signer_email?: string, signer_name?: string, simulate_corppass?: bool}
  identifier: string # The identifier.
  scheme: string # The scheme of the identifier. See <<_receiver_identifiers_list>> for a list.
  superscheme: string # The superscheme of the identifier. Should always be "iso6523-actorid-upis".
]: any -> record<corppass: record<client_redirect_fail_url: string, client_redirect_success_url: string, corppass_url: string, enabled: bool, flow_type: string, signer_email: string, signer_name: string, simulate_corppass: bool, status: string>, identifier: string, scheme: string, superscheme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id)} | format pattern "/legal_entities/{legal_entity_id}/peppol_identifiers"))
  let req_body = {"corppass": $corppass, "identifier": $identifier, "scheme": $scheme, "superscheme": $superscheme} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete PeppolIdentifier
#
# DELETE /legal_entities/{legal_entity_id}/peppol_identifiers/{superscheme}/{scheme}/{identifier}
# operationId: delete_peppol_identifier
export def "legal-entities-peppol-identifiers delete" [
  legal_entity_id: int
  superscheme: string
  scheme: string
  identifier: string
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
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  if ($superscheme | is-empty) { error make --unspanned { msg: "path parameter 'superscheme' must be non-empty" } }
  if ($scheme | is-empty) { error make --unspanned { msg: "path parameter 'scheme' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id), superscheme: (encode-path-segment $superscheme), scheme: (encode-path-segment $scheme), identifier: (encode-path-segment $identifier)} | format pattern "/legal_entities/{legal_entity_id}/peppol_identifiers/{superscheme}/{scheme}/{identifier}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Receive a new Document
#
# POST /legal_entities/{legal_entity_id}/received_documents
# operationId: receive_documenht
export def "legal-entities-received-documents receive-documenht" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: string # The Base64 encoded document.
  --body-legal-entity-id: int # The of the LegalEntity this document was received for. (format: int64)
  --parse-strategy: string@parse-strategy-completer # The attachment content type (mime type).
]: any -> record<guid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($legal_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'legal_entity_id' must be non-empty" } }
  let full_url = (build-url $base ({legal_entity_id: (encode-path-segment $legal_entity_id)} | format pattern "/legal_entities/{legal_entity_id}/received_documents"))
  let req_body = {"document": $document, "legal_entity_id": $body_legal_entity_id, "parseStrategy": $parse_strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Purchase invoice data as JSON
#
# GET /purchase_invoices/{guid}
# operationId: get_invoice_json
export def "purchase-invoices get-json" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pmv: string # The PaymentMeans version. The default (and deprecated) version 1.0 will give BankPaymentMean, DirectDebitPaymentMean, CardPaymentMean, NppPaymentMean, SeBankGiroPaymentMean, SePlusGiroPaymentMean, SgCardPaymentMean, SgGiroPaymentMean, SgPaynowPaymentMean. Version 2.0 deprecates BankPaymentMean (now CreditTransferPaymentMean), CardPaymentMean (now CreditCardPaymentMean), NppPaymentMean (now AunzNppPayidPaymentMean), SeBankGiroPaymentMean (now SeBankgiroPaymentMean -- note the lower 'g' in 'bankgiro'). It also adds OnlinePaymentServicePaymentMean, StandingAgreementPaymentMean, AunzNppPaytoPaymentMean, AunzBpayPaymentMean, AunzPostbillpayPaymentMean, AunzUriPaymentMean. (default: 1.0)
]: nothing -> record<accounting: record<code: string, list: string, list_version: string, name: string>, accounting_cost: string, allowance_charge: float, allowance_charges: table<amount_excluding_tax: float, amount_excluding_vat: string, reason: string, tax: record, vat: record>, amount_including_vat: float, attachments: table<content_type: string, document: string>, billing_reference: string, buyer_reference: string, contract_document_reference: string, delivery: record<actual_date: string, location: record<building_number: string, city: string, country: string, county: string, department: string, id: string, line1: string, line2: string, neighborhood: string, scheme_id: string, secondary_number: string, zip: string>, party: record<name: string>>, document: string, document_currency_code: string, document_totals: record<payable: float, prepaid: float, rounding: float, total: float>, document_type: string, due_date: string, external_key: string, external_user_id: string, guid: string, invoice_lines: table<accounting: record, allowance_charge: float, allowance_charge_array: list, allowance_charges: list, amount_excluding_tax: float, amount_excluding_vat: float, description: string, name: string, period_end: string, period_start: string, price: record, tax: record, units: record, vat: record>, invoice_number: string, invoice_type: string, issue_date: string, legal_entity_id: int, note: string, order_reference: string, payment_means: record<iban: string, id: string>, payment_means_array: table<account: string, branch_code: string, holder: string, mandate: string, network: string, payment_id: string, type: any>, payment_means_payment_id: string, payment_terms_note: string, period_end: string, period_start: string, project_reference: string, sender: record<billing_contact: record<email: string, first_name: string, last_name: string>, building_number: string, city: string, country: string, county: string, department: string, identifiers: list<record>, legal_name: string, line1: string, line2: string, neighborhood: string, party_name: string, peppol_identifiers: record<corppass: record, identifier: string, scheme: string, superscheme: string>, secondary_number: string, zip: string>, source: string, sub_type: string, system_generated_primary_image: bool, tax_point_date: string, tax_subtotals: table<amount_excluding_tax: float, amount_excluding_vat: string, tax: record, vat: record>, tax_system: string, vat_reverse_charge: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($guid | is-empty) { error make --unspanned { msg: "path parameter 'guid' must be non-empty" } }
  let qp = [(serialize-qp "pmv" $pmv "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({guid: (encode-path-segment $guid)} | format pattern "/purchase_invoices/{guid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pmv": $pmv} | compact), body: null}
}

# Get Purchase invoice data in a selectable format
#
# GET /purchase_invoices/{guid}/{packaging}
# operationId: get_invoice_ubl
export def "purchase-invoices get-ubl" [
  guid: string
  packaging: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pmv: string # The PaymentMeans version. The default (and deprecated) version 1.0 will give BankPaymentMean, DirectDebitPaymentMean, CardPaymentMean, NppPaymentMean, SeBankGiroPaymentMean, SePlusGiroPaymentMean, SgCardPaymentMean, SgGiroPaymentMean, SgPaynowPaymentMean. Version 2.0 deprecates BankPaymentMean (now CreditTransferPaymentMean), CardPaymentMean (now CreditCardPaymentMean), NppPaymentMean (now AunzNppPayidPaymentMean), SeBankGiroPaymentMean (now SeBankgiroPaymentMean -- note the lower 'g' in 'bankgiro'). It also adds OnlinePaymentServicePaymentMean, StandingAgreementPaymentMean, AunzNppPaytoPaymentMean, AunzBpayPaymentMean, AunzPostbillpayPaymentMean, AunzUriPaymentMean. (default: 1.0)
]: nothing -> record<external_key: string, external_user_id: string, guid: string, legal_entity_id: int, system_generated_primary_image: bool, tax_system: string, ubl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($guid | is-empty) { error make --unspanned { msg: "path parameter 'guid' must be non-empty" } }
  if ($packaging | is-empty) { error make --unspanned { msg: "path parameter 'packaging' must be non-empty" } }
  let qp = [(serialize-qp "pmv" $pmv "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({guid: (encode-path-segment $guid), packaging: (encode-path-segment $packaging)} | format pattern "/purchase_invoices/{guid}/{packaging}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pmv": $pmv} | compact), body: null}
}

# Get Purchase invoice data as JSON with a Base64-encoded UBL string in the specified version
#
# GET /purchase_invoices/{guid}/{packaging}/{package_version}
# operationId: get_invoice_ubl_versioned
export def "purchase-invoices get-ubl-versioned" [
  guid: string
  packaging: string
  package_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<external_key: string, external_user_id: string, guid: string, legal_entity_id: int, system_generated_primary_image: bool, tax_system: string, ubl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($guid | is-empty) { error make --unspanned { msg: "path parameter 'guid' must be non-empty" } }
  if ($packaging | is-empty) { error make --unspanned { msg: "path parameter 'packaging' must be non-empty" } }
  if ($package_version | is-empty) { error make --unspanned { msg: "path parameter 'package_version' must be non-empty" } }
  let full_url = (build-url $base ({guid: (encode-path-segment $guid), packaging: (encode-path-segment $packaging), package_version: (encode-path-segment $package_version)} | format pattern "/purchase_invoices/{guid}/{packaging}/{package_version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new received document
#
# POST /received_documents
# operationId: create_received_document
export def "received-documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: string # The Base64 encoded document.
  --legal-entity-id: int # The of the LegalEntity this document was received for. (format: int64)
  --parse-strategy: string@parse-strategy-completer # The attachment content type (mime type).
]: any -> record<guid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/received_documents")
  let req_body = {"document": $document, "legal_entity_id": $legal_entity_id, "parseStrategy": $parse_strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a new ReceivedDocument
#
# GET /received_documents/{guid}/{format}
# operationId: get_received_document
export def "received-documents get" [
  guid: string
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --syntax: string@syntax-completer # The syntax in which to receive the received document. (default: json)
]: nothing -> record<guid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($guid | is-empty) { error make --unspanned { msg: "path parameter 'guid' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "syntax" $syntax "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({guid: (encode-path-segment $guid), format: (encode-path-segment $format)} | format pattern "/received_documents/{guid}/{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"syntax": $syntax} | compact), body: null}
}

# GET a WebhookInstance
#
# GET /webhook_instances/
# operationId: get_webhook_instances
export def "webhook-instances get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<body: string, guid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_instances/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE a WebhookInstance
#
# DELETE /webhook_instances/{guid}
# operationId: delete_webhook_instance
export def "webhook-instances delete" [
  guid: string
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
  if ($guid | is-empty) { error make --unspanned { msg: "path parameter 'guid' must be non-empty" } }
  let full_url = (build-url $base ({guid: (encode-path-segment $guid)} | format pattern "/webhook_instances/{guid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
