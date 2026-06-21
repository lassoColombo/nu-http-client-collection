# Auto-generated client for Checks API v1.0.0
# Source: https://api.apis.guru/v2/specs/truora.com/1.0.0/openapi.json
# Auth: --token flag or $env.CHECKS_API_TOKEN

const BASE_URL = "https://api.truora.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CHECKS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "truora-api-key" => { {scheme: $scheme, headers: {Truora-API-Key: $token_val}, query: "", location: "header"} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.truora.com"] }
def auth-scheme-completer [] { ["truora-api-key"] }

# Completers for enum parameters
def country-completer [] { ["bo" "br" "cl" "co" "cr" "do" "ec" "gt" "mx" "pa" "pe" "sv" "ve"] }
def document-type-completer [] { ["civil-registration" "curp" "diplomatic-id" "dni" "driver-license" "dui" "escrow" "foreign-id" "foreign-societies" "foreigner-card" "general-registration" "identity-card" "individual-registration" "license-plate" "military-card" "name" "national-id" "nis" "nit" "nuip" "passport" "pep" "professional-card" "query" "ruc" "rui" "rut"] }
def reason-completer [] { ["absences" "aggressive-behaviour" "confidentiality-breach" "drug-dealer" "drug-possession" "drunk" "fights" "good-reputation" "identity-fraud" "rape" "sexual-harassment" "tardiness" "theft"] }
def country-completer-1 [] { ["ALL" "AR" "BR" "CL" "CO" "CR" "EC" "MX" "PE"] }
def region-completer [] { ["AC" "AL" "AM" "AP" "BA" "CE" "DF" "ES" "GO" "MA" "MG" "MS" "MT" "PA" "PB" "PE" "PI" "PR" "RJ" "RN" "RO" "RR" "RS" "SC" "SE" "SP" "TO"] }
def type-completer [] { ["company" "custom_type_name" "person" "vehicle"] }
def truora-priority-completer [] { ["high" "low" "medium"] }
def country-completer-2 [] { ["ALL" "BR" "CL" "CO" "CR" "EC" "MX" "PE"] }
def status-completer [] { ["disabled" "enabled"] }
def event-type-completer [] { ["all" "check" "continuous_check"] }
def subscriber-language-completer [] { ["af" "ar" "ca" "cs" "da" "de" "el" "en" "es" "fi" "fr" "he" "hi" "hr" "hu" "id" "it" "ja" "ko" "ms" "nb" "nl" "pl" "pr-BR" "pt" "ro" "ru" "sv" "th" "tl" "tr" "vi" "zh" "zh-CN" "zh-HK"] }
def subscriber-type-completer [] { ["email" "web"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "behavior create-report" } } | get name | first)
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

# Report Behavior
#
# POST /v1/behavior
# operationId: reportBehavior
export def "behavior create-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  birth_date: string # Birth date of reported person (format: date-time)
  country: any@country-completer # Document country
  document_id: string # Person document ID
  document_type: any@document-type-completer # Document type associated with the background check
  email: string # Reported person e-mail
  feedback_date: string # Behavior report date (format: date-time)
  first_name: string # Person first name
  last_name: string # Person last name
  --phone-number: string # Phone number of the reported person
  reason: any@reason-completer # Report reason
]: any -> record<behavior: table<birth_date: string, country: any, creation_date: string, document_id: string, document_type: any, email: string, feedback_date: string, first_name: string, last_name: string, phone_number: string, reason: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/behavior")
  let req_body = {"birth_date": $birth_date, "country": $country, "document_id": $document_id, "document_type": $document_type, "email": $email, "feedback_date": $feedback_date, "first_name": $first_name, "last_name": $last_name, "phone_number": $phone_number, "reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List Checks
#
# GET /v1/checks
# operationId: listChecks
export def "checks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-key: string # Start key value for the pagination
  --report-id: string # Report id checks to be returned
]: nothing -> record<checks: table<birth_certificate: string, check_id: string, company_summary: record, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list, status: string, statuses: list, summary: record, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record, wrong_inputs: list>, next: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_key" $start_key "scalar") (serialize-qp "report_id" $report_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_key": $start_key, "report_id": $report_id} | compact), body: null}
}

# Create a background check
#
# POST /v1/checks
# operationId: createCheck
export def "checks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --truora-priority: string@truora-priority-completer # Describes the background check priority. The amount of high priority checks is limited by country. Medium priority is used by default
  --birth-certificate: string # Person birth certificate
  --company-name: string # Company name "Don't forget this required field to complete background checks in Brazil"
  country: string@country-completer-1 # Document country
  --date-of-birth: string # Person birthdate. This date is used to get some additional information about a person and to filter homonyms in some cases. YYYY-MM-DD format, Required for complete background checks in Brazil (format: date)
  --diplomatic-id: string # Diplomatic ID
  --driver-license: string # Driver's license number
  --escrow: string # Colombian escrow
  --first-name: string # Person or entity first name. If the document type and number are not provided, the report might include homonyms. Required when searching by first name, Required in order to get complete background checks in Brazil
  --force-creation: oneof<nothing, bool> # Forces a new background check creation when true. Reuses recently created background checks otherwise
  --foreign-id: string # Person foreign ID
  --issue-date: string # Person document issue date in "YYYY-mm-dd" format (e.g. 2008-12-31) . This date is used to get some additional information about a person in some cases (format: date)
  --last-name: string # Person or entity last name. If the document type and number are not provided, the report might include homonyms. Required when searching by last name. Required in order to get complete background checks in Brazil
  --license-plate: string # Vehicle license plate
  --national-id: string # National ID
  --native-country: string # Country of birth
  --owner-document-id: string # National ID of the vehicle owner
  --owner-document-type: string # National ID, foreign ID, or tax ID
  --passport: string # Person passport
  --payment-date: string # Payment day of a vehicle circulation permit (Chile only) (format: date)
  --pep: string # ID for Venezuelans working in Colombia
  --phone-number: string # Person phone number. Required by law to notify the person their background is being checked
  --professional-card: string # Professional ID card
  --ptp: string # ID for Venezuelans working in Peru
  --region: string@region-completer # Region where the background is to be checked in addition to the region where the person is from. By default, background checks in Brazil are performed in the region where the person is from. Required for Brazil only. Allowed values are: DF: Distrito Federal, AC: Acre, AL: Alagoas, AP: Amapá, AM: Amazonas, BA: Bahía, CE: Ceará, ES: Espírito Santo, GO: Goiás, MA: Maranhão, MT: Mato Grosso, MS: Mato Grosso do Sul, MG: Minas Gerais, PA: Pará, PB: Paraíba, PR: Paraná, PE: Pernambuco, PI: Piauí, RJ: Río de Janeiro, RN: Río Grande do Norte, RS: Río Grande do Sul, RO: Rondônia, RR: Roraima, SC: Santa Catarina, SP: São Paulo, SE: Sergipe, TO : Tocantins.
  --report-id: string # Report ID the background check will be inserted into
  --state-id: string # Used for the RG (Registro Geral) identification in Brazil. This identification has different formats according to the state that issues the document. It can have numbers and letters but other characters (- * , . ) are omitted, Required in order to get complete background checks in Brazil
  --tax-id: string # Company ID used for tax payments
  type: string@type-completer # Background check type
  --user-authorized: oneof<nothing, bool> # Indicates whether the person subject to the validation authorized the validation. Must be true in order to proceed [Required for API key V1 or later]
  --vehicle-id: string # Vehicle license plate
  --verification-code: string # Verification code registered for criminal records in Peru only
  --watch: string # Indicates whether the check score is to be periodically revised and its frequency. It can be daily, weekly, monthly, yearly or have a custom frequency written as a number accompanied by d: day, w: week, m: month, y: year for instance: 3d: every three days, 2w: every two weeks. Ignore this field if the check is only to be performed once
]: any -> record<check: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, details: string, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/checks")
  let req_body = {"birth_certificate": $birth_certificate, "company_name": $company_name, "country": $country, "date_of_birth": $date_of_birth, "diplomatic_id": $diplomatic_id, "driver_license": $driver_license, "escrow": $escrow, "first_name": $first_name, "force_creation": $force_creation, "foreign_id": $foreign_id, "issue_date": $issue_date, "last_name": $last_name, "license_plate": $license_plate, "national_id": $national_id, "native_country": $native_country, "owner_document_id": $owner_document_id, "owner_document_type": $owner_document_type, "passport": $passport, "payment_date": $payment_date, "pep": $pep, "phone_number": $phone_number, "professional_card": $professional_card, "ptp": $ptp, "region": $region, "report_id": $report_id, "state_id": $state_id, "tax_id": $tax_id, "type": $type, "user_authorized": $user_authorized, "vehicle_id": $vehicle_id, "verification_code": $verification_code, "watch": $watch} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Truora-Priority": $truora_priority} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Get Health Dashboard
#
# GET /v1/checks/health
# operationId: GetHealthDashboard
export def "checks-health get-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country in ISO 3166, uppercase
  --unix-timestamp-seconds: string # Unix timestamp in seconds. Send a day timestamp to view the database hourly status for that day or send the current time to know the current database status
  --unixtimezone-offset-seconds: string # Offset between the local time and the UTC time in seconds. (e.g., Colombia is at UTC -18000 seconds)
]: nothing -> table<data_sets: list<string>, database_id: string, database_name: string, hourly_status: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "unixTimestampSeconds" $unix_timestamp_seconds "scalar") (serialize-qp "unixtimezoneOffsetSeconds" $unixtimezone_offset_seconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks/health" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country, "unixTimestampSeconds": $unix_timestamp_seconds, "unixtimezoneOffsetSeconds": $unixtimezone_offset_seconds} | compact), body: null}
}

# Get Background Check
#
# GET /v1/checks/{check_id}
# operationId: getCheck
export def "checks get" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<check: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, details: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v1/checks/{check_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Check Details
#
# GET /v1/checks/{check_id}/details
# operationId: listCheckDetails
export def "checks-details list" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-key: string # Start key value for the pagination
  --lang: string # This parameter is used to specify the language wanted for details, if not specified details will come in their original language.
]: nothing -> record<details: table<check_id: string, data_set: string, database_name: string, group: any, id: string, result: any, score: float, tables: list>, next: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let qp = [(serialize-qp "start_key" $start_key "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v1/checks/{check_id}/details") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_key": $start_key, "lang": $lang} | compact), body: null}
}

# Get PDF
#
# GET /v1/checks/{check_id}/pdf
# operationId: getPDF
export def "checks-pdf get" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Used to specify the language for the PDF, if not specified the PDF will be downloaded in Spanish.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v1/checks/{check_id}/pdf") $qp)
  let accept_val = "PDF"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang} | compact), body: null}
}

# Create PDF
#
# POST /v1/checks/{check_id}/pdf
# operationId: CreatePDF
export def "checks-pdf create" [
  check_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v1/checks/{check_id}/pdf"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Custom Type
#
# DELETE /v1/config
# operationId: DeleteCustomType
export def "config delete-custom-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # Name of the custom type to be deleted
  --country: string@country-completer-2 # Country where the custom type is valid
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type, "country": $country} | compact), body: null}
}

# List Score Configurations
#
# GET /v1/config
# operationId: listScoreConfigs
export def "config list-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-key: string # The key to start the pagination
]: nothing -> record<score_configs: table<ScoreConfigByCountry: list>> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_key" $start_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_key": $start_key} | compact), body: null}
}

# Create Score Configurations
#
# POST /v1/config
# operationId: createScoreConfig
export def "config create-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string@country-completer-1 # Country where this set of rules applies. Use "all" if the check type searches by name by relying on international databases
  --dataset-affiliations-and-insurances: float # Affiliation and insurance weight for score calculation. From 0 to 1 (format: float)
  --dataset-alert-in-media: float # Alert in media weight for score calculation. From 0 to 1 (format: float)
  --dataset-business-background: float # Business background weight for score calculation. From 0 to 1 (format: float)
  --dataset-criminal-record: float # Criminal record weight for score calculation. From 0 to 1 (format: float)
  --dataset-driving-licenses: float # Driving license weight for score calculation. From 0 to 1 (format: float)
  --dataset-international-background: float # International background weight for score calculation. From 0 to 1 (format: float)
  --dataset-legal-background: float # Legal background weight for score calculation. From 0 to 1 (format: float)
  --dataset-personal-identity: float # Personal identity weight for score calculation. From 0 to 1 (format: float)
  --dataset-professional-background: float # Professional background weight for score calculation. From 0 to 1 (format: float)
  --dataset-taxes-and-finances: float # Taxes and financial background weight for score calculation. From 0 to 1 (format: float)
  --dataset-traffic-fines: float # Traffic fines weight for score calculation. From 0 to 1 (format: float)
  --dataset-vehicle-information: float # Vehicle information weight for score calculation. From 0 to 1 (format: float)
  --dataset-vehicle-permits: float # Vehicle certificate background weight for score calculation. From 0 to 1 (format: float)
  type: string # Score configuration name. It cannot be person, vehicle, or company
]: any -> record<ScoreConfigByCountry: table<data_set: string, weight: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/config")
  let req_body = {"country": $country, "dataset_affiliations_and_insurances": $dataset_affiliations_and_insurances, "dataset_alert_in_media": $dataset_alert_in_media, "dataset_business_background": $dataset_business_background, "dataset_criminal_record": $dataset_criminal_record, "dataset_driving_licenses": $dataset_driving_licenses, "dataset_international_background": $dataset_international_background, "dataset_legal_background": $dataset_legal_background, "dataset_personal_identity": $dataset_personal_identity, "dataset_professional_background": $dataset_professional_background, "dataset_taxes_and_finances": $dataset_taxes_and_finances, "dataset_traffic_fines": $dataset_traffic_fines, "dataset_vehicle_information": $dataset_vehicle_information, "dataset_vehicle_permits": $dataset_vehicle_permits, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Update Custom Type
#
# PUT /v1/config
# operationId: UpdateCustomType
export def "config update-custom-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string@country-completer-1 # Country where this set of rules applies. Use "all" if the check type searches by name by relying on international databases
  --dataset-affiliations-and-insurances: float # Affiliation and insurance weight for score calculation. From 0 to 1 (format: float)
  --dataset-alert-in-media: float # Alert in media weight for score calculation. From 0 to 1 (format: float)
  --dataset-business-background: float # Business background weight for score calculation. From 0 to 1 (format: float)
  --dataset-criminal-record: float # Criminal record weight for score calculation. From 0 to 1 (format: float)
  --dataset-driving-licenses: float # Driving license weight for score calculation. From 0 to 1 (format: float)
  --dataset-international-background: float # International background weight for score calculation. From 0 to 1 (format: float)
  --dataset-legal-background: float # Legal background weight for score calculation. From 0 to 1 (format: float)
  --dataset-personal-identity: float # Personal identity weight for score calculation. From 0 to 1 (format: float)
  --dataset-professional-background: float # Professional background weight for score calculation. From 0 to 1 (format: float)
  --dataset-taxes-and-finances: float # Taxes and financial background weight for score calculation. From 0 to 1 (format: float)
  --dataset-traffic-fines: float # Traffic fines weight for score calculation. From 0 to 1 (format: float)
  --dataset-vehicle-information: float # Vehicle information weight for score calculation. From 0 to 1 (format: float)
  --dataset-vehicle-permits: float # Vehicle certificate background weight for score calculation. From 0 to 1 (format: float)
  type: string # Score configuration name. It cannot be person, vehicle, or company
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/config")
  let req_body = {"country": $country, "dataset_affiliations_and_insurances": $dataset_affiliations_and_insurances, "dataset_alert_in_media": $dataset_alert_in_media, "dataset_business_background": $dataset_business_background, "dataset_criminal_record": $dataset_criminal_record, "dataset_driving_licenses": $dataset_driving_licenses, "dataset_international_background": $dataset_international_background, "dataset_legal_background": $dataset_legal_background, "dataset_personal_identity": $dataset_personal_identity, "dataset_professional_background": $dataset_professional_background, "dataset_taxes_and_finances": $dataset_taxes_and_finances, "dataset_traffic_fines": $dataset_traffic_fines, "dataset_vehicle_information": $dataset_vehicle_information, "dataset_vehicle_permits": $dataset_vehicle_permits, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Lists all continuous checks
#
# GET /v1/continuous-checks
# operationId: ListContinuousChecks
export def "continuous-checks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<continuous_checks: table<birth_certificate: string, check_id: string, company_summary: record, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list, status: string, statuses: list, summary: record, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record, wrong_inputs: list>, next: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/continuous-checks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a continuous check that will run background checks recurrently according to the frequency provided.
#
# POST /v1/continuous-checks
# operationId: createContinuousCheck
export def "continuous-checks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-id: string # Background checks to be processed recurrently
  --frequency: string # Time between background checks. It can be daily, weekly, monthly, yearly or have a custom frequency written as a number accompanied by d: day, w: week, m: month, y: year for instance: 3d: every three days, 2w: every two weeks
  --status: string # Indicates whether the background checks must be processed recurrently (enabled | disabled)
]: any -> record<ContinuousCheckID: string, ContinuousCheckStatus: string, CreationDate: string, Enabled: bool, Frequency: string, History: record<changes: list<record>, check_id: string, continuous_check_id: string, creation_date: string, previous_check_id: string>, LastCheckID: string, NextRunDate: string, OriginalCheck: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, UpdateDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/continuous-checks")
  let req_body = {"check_id": $check_id, "frequency": $frequency, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Lists history associated with a Check. It can be paginated
#
# GET /v1/continuous-checks/{continuous_check_id}
# operationId: GetContinuousCheck
export def "continuous-checks get" [
  continuous_check_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ContinuousCheckID: string, ContinuousCheckStatus: string, CreationDate: string, Enabled: bool, Frequency: string, History: record<changes: list<record>, check_id: string, continuous_check_id: string, creation_date: string, previous_check_id: string>, LastCheckID: string, NextRunDate: string, OriginalCheck: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, UpdateDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($continuous_check_id | is-empty) { error make --unspanned { msg: "path parameter 'continuous_check_id' must be non-empty" } }
  let full_url = (build-url $base ({continuous_check_id: (encode-path-segment $continuous_check_id)} | format pattern "/v1/continuous-checks/{continuous_check_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a continuous check
#
# PUT /v1/continuous-checks/{continuous_check_id}
# operationId: UpdateContinuousCheck
export def "continuous-checks update" [
  continuous_check_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  frequency: string # Time between background checks
  status: string@status-completer # Indicates whether the background checks must be processed recurrently
]: any -> record<ContinuousCheckID: string, ContinuousCheckStatus: string, CreationDate: string, Enabled: bool, Frequency: string, History: record<changes: list<record>, check_id: string, continuous_check_id: string, creation_date: string, previous_check_id: string>, LastCheckID: string, NextRunDate: string, OriginalCheck: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, UpdateDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($continuous_check_id | is-empty) { error make --unspanned { msg: "path parameter 'continuous_check_id' must be non-empty" } }
  let full_url = (build-url $base ({continuous_check_id: (encode-path-segment $continuous_check_id)} | format pattern "/v1/continuous-checks/{continuous_check_id}"))
  let req_body = {"frequency": $frequency, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Lists background check logs. It can be paginated
#
# GET /v1/continuous-checks/{continuous_check_id}/history
export def "continuous-checks-history get" [
  continuous_check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<history: table<dataset_score_changes: float, score_changes: list>, next: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($continuous_check_id | is-empty) { error make --unspanned { msg: "path parameter 'continuous_check_id' must be non-empty" } }
  let full_url = (build-url $base ({continuous_check_id: (encode-path-segment $continuous_check_id)} | format pattern "/v1/continuous-checks/{continuous_check_id}/history"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists all hooks
#
# GET /v1/hooks
# operationId: listHook
export def "hooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<hooks: table<actions: list, event_type: string, signing_key: string, status: string, subscriber_type: string, subscriber_url: string>, next: string, self: string, signing_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a hook subscription
#
# POST /v1/hooks
# operationId: createHook
export def "hooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list<string> # Actions you want to be notified. Possible inputs are created, started, and finished or any combination of those three
  event_type: string@event-type-completer # The entity events the client wants to subscribe
  --status: string@status-completer # indicates whether the hook is active or not. enabled by default
  --subscriber-address: string # Email address where the notification is to be sent. Required if subscriber_type was set to email
  --subscriber-language: string@subscriber-language-completer # Language for the notification to be sent
  --subscriber-name: string # Name of the person to be notified
  subscriber_type: string@subscriber-type-completer # A platform with an endpoint ready to process the information
  --subscriber-url: string # URL where the notification is to be sent. Required only if subscriber_type is set to web
]: any -> record<actions: list<string>, event_type: string, signing_key: string, status: string, subscriber_type: string, subscriber_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hooks")
  let req_body = {"actions": $actions, "event_type": $event_type, "status": $status, "subscriber_address": $subscriber_address, "subscriber_language": $subscriber_language, "subscriber_name": $subscriber_name, "subscriber_type": $subscriber_type, "subscriber_url": $subscriber_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Deletes hook
#
# DELETE /v1/hooks/{hook_id}
# operationId: deletHook
export def "hooks delete-delet" [
  hook_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/v1/hooks/{hook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates hook
#
# PUT /v1/hooks/{hook_id}
# operationId: updateHook
export def "hooks update" [
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list<string> # Actions you want to be notified. Possible inputs are created, started, and finished or any combination of those three
  event_type: string@event-type-completer # The entity events the client wants to subscribe
  --status: string@status-completer # indicates whether the hook is active or not. enabled by default
  --subscriber-address: string # Email address where the notification is to be sent. Required if subscriber_type was set to email
  --subscriber-language: string@subscriber-language-completer # Language for the notification to be sent
  --subscriber-name: string # Name of the person to be notified
  subscriber_type: string@subscriber-type-completer # A platform with an endpoint ready to process the information
  --subscriber-url: string # URL where the notification is to be sent. Required only if subscriber_type is set to web
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/v1/hooks/{hook_id}"))
  let req_body = {"actions": $actions, "event_type": $event_type, "status": $status, "subscriber_address": $subscriber_address, "subscriber_language": $subscriber_language, "subscriber_name": $subscriber_name, "subscriber_type": $subscriber_type, "subscriber_url": $subscriber_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/x-www-form-urlencoded"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List Reports
#
# GET /v1/reports
# operationId: listReports
export def "reports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-key: string # Start value for pagination.
  --username: string # filter reports created by the specified username
]: nothing -> record<next: string, reports: table<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_key" $start_key "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_key": $start_key, "username": $username} | compact), body: null}
}

# Create Report
#
# POST /v1/reports
# operationId: createReport
export def "reports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Report name
]: any -> record<checks: string, report: record<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/reports")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Get Report
#
# GET /v1/reports/{report_id}
# operationId: getReport
export def "reports get" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<checks: string, report: record<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'report_id' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/v1/reports/{report_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Batch Upload
#
# POST /v1/reports/{report_id}/upload
# operationId: batchUpload
export def "reports-upload upload-batch" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: list<string> # Uploaded file name
]: any -> record<checks: string, report: record<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "truora-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'report_id' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/v1/reports/{report_id}/upload"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}
