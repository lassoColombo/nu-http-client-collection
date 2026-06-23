# Auto-generated client for Health ID Service v1.0
# Source: https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-healthid/1.0/openapi.json
# Auth: --token flag or $env.HEALTH_ID_SERVICE_TOKEN

const BASE_URL = "https://healthidsbx.ndhm.gov.in/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HEALTH_ID_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "x-hip-id" => { {scheme: $scheme, headers: {X-HIP-ID: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://healthidsbx.ndhm.gov.in/api"] }
def auth-scheme-completer [] { ["bearer" "x-hip-id"] }

# Completers for enum parameters
def accept-completer [] { ["*/*" "image/png"] }
def auth-type-completer [] { ["FINGERSCAN" "IRIS" "OTP"] }
def auth-method-completer [] { ["AADHAAR_BIO" "AADHAAR_OTP" "DEMOGRAPHICS" "MOBILE_OTP" "PASSWORD"] }
def benefit-doc-type-completer [] { ["ADOPTION_CERTIFICATE" "BIRTH_CERTIFICATE" "CERTIFICATE_IDENTIFY" "DISABILITY_ID_CARD" "DRIVING_LICENSE" "FREEDOM_FIGHTER_PHOTO_CARD" "KISSAN_PHOTO_PASSBOOK" "MARRIAGE_CERTIFICATE" "MNREGA_JOB_CARD" "OTHER_GOVERNMENT_ID" "PAN_CARD" "PENSIONER_PHOTO_CARD" "RATION_CARD" "VOTER_ID_CARD"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-aadhaar-generate-otp create-generatere-kyc-aadhar-using" } } | get name | first)
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

# Generate Aadhaar OTP on registrered for link account with aadhar number
#
# POST /v1/account/aadhaar/generateOTP
# operationId: generatereKycAadharOTPUsingPOST
export def "account-aadhaar-generate-otp create-generatere-kyc-aadhar-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
]: nothing -> record<txnId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/aadhaar/generateOTP")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Verify Aadhaar OTP to complete KYC/re-KYC verification.
#
# POST /v1/account/aadhaar/verifyOTP
# operationId: verifyAadharOTPOnlyUsingPOST_1
export def "account-aadhaar-verify-otp create-aadhar-only-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
  --otp: string
  --restrictions: string
  --txn-id: string
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/aadhaar/verifyOTP")
  let req_body = {"otp": $otp, "restrictions": $restrictions, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get List of Benefits associated with HealthID.
#
# GET /v1/account/benefits
# operationId: getBenefitsUsingGET
export def "account-benefits get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer XToken)
]: nothing -> record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/benefits")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Change password via Aadhar for heath id.
#
# POST /v1/account/change/passwd/byAadhaar
# operationId: changePasswordViaAadharUsingPOST
export def "account-change-passwd-by-aadhaar create-password-via-aadhar-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
  --new-password: string
  --otp: string
  --txn-id: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/change/passwd/byAadhaar")
  let req_body = {"newPassword": $new_password, "otp": $otp, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Change password via mobile for heath id.
#
# POST /v1/account/change/passwd/byMobile
# operationId: changePasswordViaMobileUsingPOST
export def "account-change-passwd-by-mobile create-password-via-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
  --new-password: string
  --otp: string
  --txn-id: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/change/passwd/byMobile")
  let req_body = {"newPassword": $new_password, "otp": $otp, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate Aadhaar OTP on registrered mobile number.
#
# GET /v1/account/change/passwd/generateAadhaarOTP
# operationId: generateAadharOTPUsingGET
export def "account-change-passwd-generate-aadhaar-otp get-aadhar-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/change/passwd/generateAadhaarOTP")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate Mobile OTP to start registration.
#
# GET /v1/account/change/passwd/generateMobileOTP
# operationId: generateMobileOTPUsingGET
export def "account-change-passwd-generate-mobile-otp get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/change/passwd/generateMobileOTP")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Change password via password for heath id.
#
# POST /v1/account/change/password
# operationId: changePasswordViaUsingPOST
export def "account-change-password create-via-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
  --new-password: string
  --old-password: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/change/password")
  let req_body = {"newPassword": $new_password, "oldPassword": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate Health ID card in PDF format
#
# GET /v1/account/getCard
# operationId: generateCardUsingGET
export def "account-get-card generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
]: nothing -> record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/getCard")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate Health ID card PNG
#
# GET /v1/account/getPngCard
# operationId: generatePngCardUsingGET
export def "account-get-png-card generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
]: nothing -> record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/getPngCard")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate Health ID card SVG
#
# GET /v1/account/getSvgCard
# operationId: generateSvgCardUsingGET
export def "account-get-svg-card generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
]: nothing -> record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/getSvgCard")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete account
#
# DELETE /v1/account/profile
# operationId: deleteAccountUsingDELETE
export def "account-profile delete-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/profile")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get account information.
#
# GET /v1/account/profile
# operationId: getAccountInformationUsingGET
export def "account-profile get-information-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer XToken)
]: nothing -> record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/profile")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update account information
#
# POST /v1/account/profile
# operationId: updateAccountInformationUsingPOST
export def "account-profile update-information-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
  --address: string
  --day-of-birth: string
  --district-code: string
  --email: string
  --first-name: string
  --health-id: string
  --last-name: string
  --middle-name: string
  --month-of-birth: string
  --password: string
  --pincode: int # format: int32
  --profile-photo: string
  --state-code: string
  --subdistrict-code: string
  --town-code: string
  --village-code: string
  --ward-code: string
  --year-of-birth: string
]: any -> record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/profile")
  let req_body = {"address": $address, "dayOfBirth": $day_of_birth, "districtCode": $district_code, "email": $email, "firstName": $first_name, "healthId": $health_id, "lastName": $last_name, "middleName": $middle_name, "monthOfBirth": $month_of_birth, "password": $password, "pincode": $pincode, "profilePhoto": $profile_photo, "stateCode": $state_code, "subdistrictCode": $subdistrict_code, "townCode": $town_code, "villageCode": $village_code, "wardCode": $ward_code, "yearOfBirth": $year_of_birth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Quick Response code in PNG format for this account.
#
# GET /v1/account/qrCode
# operationId: getQrCodeUsingGET
export def "account-qr-code get-using" [
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
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer XToken)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/qrCode")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Validate auth token
#
# POST /v1/account/token
# operationId: validateTokenUsingPOST
export def "account-token validate-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --auth-token: string
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/token")
  let req_body = {"authToken": $auth_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Authenticate using Health ID number / Health ID and password
#
# POST /v1/auth/authPassword
# operationId: authenticateWithPasswordUsingPOST
export def "auth-auth-password create-authenticate-with-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --health-id: string
  --password: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/authPassword")
  let req_body = {"healthId": $health_id, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Authenticate request to generate Mobile OTP using Health ID number / Health ID
#
# POST /v1/auth/authWithMobile
# operationId: authenticateUserUsingPOST
export def "auth-auth-with-mobile create-authenticate-user-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --healthid: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/authWithMobile")
  let req_body = {"healthid": $healthid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Authenticate using verified Mobile Number and user data
#
# POST /v1/auth/authWithMobileToken
# operationId: authWithMobileTokenUsingPOST
export def "auth-auth-with-mobile-token create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --gender: string
  --health-id: string
  --name: string
  --body-token: string
  txn_id: string
  --year-of-birth: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/authWithMobileToken")
  let req_body = {"gender": $gender, "healthId": $health_id, "name": $name, "token": $body_token, "txnId": $txn_id, "yearOfBirth": $year_of_birth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Auth token public key.
#
# GET /v1/auth/cert
# operationId: certUsingGET
export def "auth-cert get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/cert")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Authentication with Aadhaar Biometric based auth transaction.
#
# POST /v1/auth/confirmWithAadhaarBio
# operationId: confirmWithAadhaarBioUsingPOST
export def "auth-confirm-with-aadhaar-bio create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --auth-type: string@auth-type-completer
  --bio-type: string
  --pid: string
  --txn-id: string # format: uuid
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/confirmWithAadhaarBio")
  let req_body = {"authType": $auth_type, "bioType": $bio_type, "pid": $pid, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Authentication with Aadhaar OTP based auth transaction.
#
# POST /v1/auth/confirmWithAadhaarOtp
# operationId: confirmWithAadhaarOtpUsingPOST
export def "auth-confirm-with-aadhaar-otp create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  otp: string
  txn_id: string # format: uuid
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/confirmWithAadhaarOtp")
  let req_body = {"otp": $otp, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Authenticate using demographic data of user.
#
# POST /v1/auth/confirmWithDemographics
# operationId: confirmWithDemographicsUsingPOST
export def "auth-confirm-with-demographics create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --gender: string
  --name: string
  txn_id: string # format: uuid
  --year-of-birth: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/confirmWithDemographics")
  let req_body = {"gender": $gender, "name": $name, "txnId": $txn_id, "yearOfBirth": $year_of_birth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Authentication with Mobile OTP based auth transaction.
#
# POST /v1/auth/confirmWithMobileOTP
# operationId: confirmWithMobileUsingPOST
export def "auth-confirm-with-mobile-otp create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --otp: string
  --txn-id: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/confirmWithMobileOTP")
  let req_body = {"otp": $otp, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Authentication with PASSWORD based auth transaction.
#
# POST /v1/auth/confirmWithPassword
# operationId: authAccountPasswordRequestUsingPOST
export def "auth-confirm-with-password request-account-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  password: string
  txn_id: string # format: uuid
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/confirmWithPassword")
  let req_body = {"password": $password, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Initiate authentication process for given Health ID
#
# POST /v1/auth/init
# operationId: initiateAuthUsingPOST
export def "auth-init create-initiate-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  auth_method: string@auth-method-completer
  --healthid: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/init")
  let req_body = {"authMethod": $auth_method, "healthid": $healthid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Resend Aadhaar/Mobile OTP for Authentication Transaction.
#
# POST /v1/auth/resendAuthOTP
# operationId: resendAuthMobileOTPUsingPOST
export def "auth-resend-auth-otp create-mobile-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  txn_id: string
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/resendAuthOTP")
  let req_body = {"txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify aadhar OTP sent as part of forgetHealth id.
#
# POST /v1/forgot/healthId/aadhaar
# operationId: retrievalHealthIdByAadharUsingPOST
export def "forgot-health-id-aadhaar create-retrieval-by-aadhar-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  otp: string
  txn_id: string # format: uuid
]: any -> record<healthId: string, healthIdNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/forgot/healthId/aadhaar")
  let req_body = {"otp": $otp, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate Aadhaar OTP on registrered mobile number
#
# POST /v1/forgot/healthId/aadhaar/generateOtp
# operationId: generateAadharOTPUsingPOST_1
export def "forgot-health-id-aadhaar-generate-otp create-aadhar-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --aadhaar: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/forgot/healthId/aadhaar/generateOtp")
  let req_body = {"aadhaar": $aadhaar} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify Mobile OTP sent as part of forgetHealth id.
#
# POST /v1/forgot/healthId/mobile
# operationId: retrievalHealthIdByMobileUsingPOST
export def "forgot-health-id-mobile create-retrieval-by-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --day-of-birth: string
  --first-name: string
  --gender: string
  --last-name: string
  --middle-name: string
  --month-of-birth: string
  --name: string
  --otp: string
  txn_id: string
  --year-of-birth: string
]: any -> record<healthId: string, healthIdNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/forgot/healthId/mobile")
  let req_body = {"dayOfBirth": $day_of_birth, "firstName": $first_name, "gender": $gender, "lastName": $last_name, "middleName": $middle_name, "monthOfBirth": $month_of_birth, "name": $name, "otp": $otp, "txnId": $txn_id, "yearOfBirth": $year_of_birth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate Mobile OTP to start registration
#
# POST /v1/forgot/healthId/mobile/generateOtp
# operationId: generateMobileOTPUsingPOST
export def "forgot-health-id-mobile-generate-otp create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --mobile: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/forgot/healthId/mobile/generateOtp")
  let req_body = {"mobile": $mobile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of districts in a given State as per LGD.
#
# GET /v1/ha/lgd/districts
# operationId: getDistrictsInStateUsingGET
export def "ha-lgd-districts get-in-state-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state-code: string # stateCode
  --accept-language: string
]: nothing -> table<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stateCode" $state_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ha/lgd/districts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stateCode": $state_code} | compact), body: null}
}

# Get a list of states as per LGD.
#
# GET /v1/ha/lgd/states
# operationId: getStatesUsingGET
export def "ha-lgd-states get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
]: nothing -> table<code: string, districts: list<record>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ha/lgd/states")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete tag against HealthId.
#
# DELETE /v1/ha/tags
# operationId: deleteTagUsingDELETE
export def "ha-tags delete-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --body: any
]: any -> table<healthId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ha/tags")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "*/*" $req_body {query: {}, body: $req_body}
}

# Get list of Tags against HealthID.
#
# GET /v1/ha/tags
# operationId: getTagsUsingGET
export def "ha-tags get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer X-Token)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ha/tags")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add tag against HealthId.
#
# POST /v1/ha/tags
# operationId: addTagUsingPOST
export def "ha-tags create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --health-id: string
  --tags: record
]: any -> table<healthId: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ha/tags")
  let req_body = {"healthId": $health_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate token for heath facility id.
#
# POST /v1/health/facility/authenticate
# operationId: authenticateHealthFacilityUsingPOST
export def "health-facility-authenticate create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --hfr-uid: string
  --password: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health/facility/authenticate")
  let req_body = {"hfrUid": $hfr_uid, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Change password for heath facility id.
#
# POST /v1/health/facility/change/password
# operationId: changePasswordUsingPOST
export def "health-facility-change-password create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --hfr-uid: string
  --new-password: string
  --old-password: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health/facility/change/password")
  let req_body = {"hfrUid": $hfr_uid, "newPassword": $new_password, "oldPassword": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate Health ID card SVG
#
# POST /v1/health/facility/createHealthIdWithPreVerified
# operationId: createAadhaarAccountUsingPOST_1
export def "health-facility-create-health-id-with-pre-verified create-aadhaar-account-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --email: string
  --first-name: string
  --health-id: string
  --last-name: string
  --middle-name: string
  --password: string
  --profile-photo: string
  --txn-id: string
]: any -> record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health/facility/createHealthIdWithPreVerified")
  let req_body = {"email": $email, "firstName": $first_name, "healthId": $health_id, "lastName": $last_name, "middleName": $middle_name, "password": $password, "profilePhoto": $profile_photo, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generates password for heath facility id.
#
# POST /v1/health/facility/generate/password
# operationId: generatePasswordUsingPOST
export def "health-facility-generate-password create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --hfr-uid: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health/facility/generate/password")
  let req_body = {"hfrUid": $hfr_uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate health hacility OTP on registrered mobile number
#
# POST /v1/health/facility/generateOtp
# operationId: generateFacilityOTPUsingPOST
export def "health-facility-generate-otp create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --x-token: string # Auth Token (e.g. Bearer XToken)
  --aadhaar: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health/facility/generateOtp")
  let req_body = {"aadhaar": $aadhaar} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# generateSvgCard
#
# GET /v1/health/facility/getSvgCard
# operationId: generateSvgCardUsingGET_1
export def "health-facility-get-svg-card generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --health-id: string # Your health id (e.g. demo@ndhm)
  --x-token: string # Auth Token (e.g. Bearer X-Token)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health/facility/getSvgCard")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "Health-ID": $health_id, "X-Token": $x_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reset password for heath facility id.
#
# POST /v1/health/facility/reset/password
# operationId: resetPasswordUsingPOST
export def "health-facility-reset-password create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --hfr-uid: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health/facility/reset/password")
  let req_body = {"hfrUid": $hfr_uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate Aadhaar OTP on registrered mobile number
#
# POST /v1/hid/benefit/aadhaar/generateOtp
# operationId: generateAadharOTPUsingPOST_2
export def "hid-benefit-aadhaar-generate-otp create-aadhar-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --aadhaar: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/aadhaar/generateOtp")
  let req_body = {"aadhaar": $aadhaar} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create health id using Aadhaar Number Otp.
#
# POST /v1/hid/benefit/aadhaar/verifyAadharOtp
# operationId: verifyAadharOtpUsingPOST
export def "hid-benefit-aadhaar-verify-aadhar-otp create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-id: string
  --benefit-name: string
  --consent-health-id: oneof<nothing, bool>
  --mobile-number: string
  --otp: string
  --txn-id: string
  --validity: string
]: any -> record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/aadhaar/verifyAadharOtp")
  let req_body = {"autoGeneratedBenefitId": $auto_generated_benefit_id, "benefitId": $benefit_id, "benefitName": $benefit_name, "consentHealthId": $consent_health_id, "mobileNumber": $mobile_number, "otp": $otp, "txnId": $txn_id, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create health id using Biometric Authentication.
#
# POST /v1/hid/benefit/aadhaar/verifyBio
# operationId: verifyBioUsingPOST
export def "hid-benefit-aadhaar-verify-bio create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --aadhaar: string
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-id: string
  --benefit-name: string
  --bio-type: string
  --consent-health-id: oneof<nothing, bool>
  --mobile-number: string
  --pid: string
  --validity: string
]: any -> record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/aadhaar/verifyBio")
  let req_body = {"aadhaar": $aadhaar, "autoGeneratedBenefitId": $auto_generated_benefit_id, "benefitId": $benefit_id, "benefitName": $benefit_name, "bioType": $bio_type, "consentHealthId": $consent_health_id, "mobileNumber": $mobile_number, "pid": $pid, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create health id using Aadhaar Demo Auth.
#
# POST /v1/hid/benefit/createHealthId/demo/auth
# operationId: createHealthIdByDemoAuthUsingPOST
export def "hid-benefit-create-health-id-demo-auth create-by-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --aadhar-number: string
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-id: string
  --benefit-name: string
  --consent-health-id: oneof<nothing, bool>
  --date-of-birth: string
  --gender: string
  --mobile-number: string
  --name: string
  --validity: string
]: any -> record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/createHealthId/demo/auth")
  let req_body = {"aadharNumber": $aadhar_number, "autoGeneratedBenefitId": $auto_generated_benefit_id, "benefitId": $benefit_id, "benefitName": $benefit_name, "consentHealthId": $consent_health_id, "dateOfBirth": $date_of_birth, "gender": $gender, "mobileNumber": $mobile_number, "name": $name, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# De-Linked with hid.
#
# POST /v1/hid/benefit/delink
# operationId: delinkHidBenefitUsingPOST
export def "hid-benefit-delink create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --benefit-name: string
  --uid-token: string
]: any -> record<benefitName: string, healthId: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/delink")
  let req_body = {"benefitName": $benefit_name, "uidToken": $uid_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Linked with hid.
#
# POST /v1/hid/benefit/link
# operationId: linkHidBenefitUsingPOST
export def "hid-benefit-link create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --benefit-id: string
  --benefit-name: string
  --state-code: string
  --uid-token: string
  --validity: string
]: any -> record<benefitName: string, healthId: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/link")
  let req_body = {"benefitId": $benefit_id, "benefitName": $benefit_name, "stateCode": $state_code, "uidToken": $uid_token, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create health id using mobile Authentication.
#
# POST /v1/hid/benefit/mobile/createHealthId
# operationId: createHealthIdByMobileUsingPOST
export def "hid-benefit-mobile-create-health-id create-by-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-doc-type: string@benefit-doc-type-completer
  --benefit-id: string
  --benefit-name: string
  --consent-health-id: oneof<nothing, bool>
  --date-of-birth: string
  --doc-number: string
  --file-type: string
  --gender: string
  --name: string
  --otp: string
  --txn-id: string
  --uploaded-doc: string
  --validity: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/mobile/createHealthId")
  let req_body = {"autoGeneratedBenefitId": $auto_generated_benefit_id, "benefitDocType": $benefit_doc_type, "benefitId": $benefit_id, "benefitName": $benefit_name, "consentHealthId": $consent_health_id, "dateOfBirth": $date_of_birth, "docNumber": $doc_number, "fileType": $file_type, "gender": $gender, "name": $name, "otp": $otp, "txnId": $txn_id, "uploadedDoc": $uploaded_doc, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate mobile OTP on registrered mobile number
#
# POST /v1/hid/benefit/mobile/generateOtp
# operationId: generateMobileOtpUsingPOST
export def "hid-benefit-mobile-generate-otp create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --mobile: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/mobile/generateOtp")
  let req_body = {"mobile": $mobile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create health id using notify Benefit.
#
# POST /v1/hid/benefit/notify/benefit
# operationId: notifyBenefitUsingPOST
export def "hid-benefit-notify-benefit create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --aadhar-number-or-uid-token: string
  --auto-generated-benefit-id: oneof<nothing, bool>
  --benefit-id: string
  --benefit-name: string
  --consent-health-id: oneof<nothing, bool>
  --date-of-birth: string
  --gender: string
  --mobile-number: string
  --name: string
  --state-code: string
  --validity: string
]: any -> record<address: string, authMethods: list<string>, benefitId: string, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, status: string, subDistrictCode: string, subdistrictName: string, tags: record, token: string, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/notify/benefit")
  let req_body = {"aadharNumberOrUidToken": $aadhar_number_or_uid_token, "autoGeneratedBenefitId": $auto_generated_benefit_id, "benefitId": $benefit_id, "benefitName": $benefit_name, "consentHealthId": $consent_health_id, "dateOfBirth": $date_of_birth, "gender": $gender, "mobileNumber": $mobile_number, "name": $name, "stateCode": $state_code, "validity": $validity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search health id number using aadhar or aadhar token.
#
# POST /v1/hid/benefit/search/aadhaar
# operationId: findByAadharUsingPOST
export def "hid-benefit-search-aadhaar find-by-aadhar-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --aadhaar: string
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/search/aadhaar")
  let req_body = {"aadhaar": $aadhaar} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search benefit using health id number.
#
# POST /v1/hid/benefit/search/healthIdNumber
# operationId: findByHealthIdUsingPOST
export def "hid-benefit-search-health-id-number find-by-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --benefit-id: string
  --health-id: string
]: any -> table<benefitId: string, benefitName: string, healthIdNumber: string, stateCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/search/healthIdNumber")
  let req_body = {"benefitId": $benefit_id, "healthId": $health_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update mobile number for account.
#
# POST /v1/hid/benefit/update/mobile
# operationId: updateMobileInformationUsingPOST
export def "hid-benefit-update-mobile create-information-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --health-id-number: string
  --mobile: string
]: any -> record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/update/mobile")
  let req_body = {"healthIdNumber": $health_id_number, "mobile": $mobile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update account information
#
# POST /v1/hid/benefit/update/profile
# operationId: updateAccountInformationUsingPOST_1
export def "hid-benefit-update-profile create-account-information-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --address: string
  --day-of-birth: string
  --district-code: string
  --email: string
  --first-name: string
  --health-id: string
  --health-id-number: string
  --last-name: string
  --middle-name: string
  --month-of-birth: string
  --password: string
  --pincode: int # format: int32
  --profile-photo: string
  --state-code: string
  --subdistrict-code: string
  --town-code: string
  --village-code: string
  --ward-code: string
  --year-of-birth: string
]: any -> record<address: string, authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, kycVerified: bool, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, pincode: string, profilePhoto: string, stateCode: string, stateName: string, subDistrictCode: string, subdistrictName: string, tags: record, townCode: string, townName: string, villageCode: string, villageName: string, wardCode: string, wardName: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/update/profile")
  let req_body = {"address": $address, "dayOfBirth": $day_of_birth, "districtCode": $district_code, "email": $email, "firstName": $first_name, "healthId": $health_id, "healthIdNumber": $health_id_number, "lastName": $last_name, "middleName": $middle_name, "monthOfBirth": $month_of_birth, "password": $password, "pincode": $pincode, "profilePhoto": $profile_photo, "stateCode": $state_code, "subdistrictCode": $subdistrict_code, "townCode": $town_code, "villageCode": $village_code, "wardCode": $ward_code, "yearOfBirth": $year_of_birth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update health id status .
#
# POST /v1/hid/benefit/update/status
# operationId: updateStatusUsingPOST
export def "hid-benefit-update-status create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --health-id-number: string
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/hid/benefit/update/status")
  let req_body = {"healthIdNumber": $health_id_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify Aadhaar OTP on registrered mobile number to create Health ID.
#
# POST /v1/registration/aadhaar/createHealthIdWithAadhaarOtp
# operationId: verifyAadharOTPUsingPOST
export def "registration-aadhaar-create-health-id-with-aadhaar-otp verify-aadhar-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --email: string
  --first-name: string
  --last-name: string
  --middle-name: string
  --mobile: string
  --otp: string
  --password: string
  --profile-photo: string
  --restrictions: string
  --txn-id: string
  --username: string
]: any -> record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/aadhaar/createHealthIdWithAadhaarOtp")
  let req_body = {"email": $email, "firstName": $first_name, "lastName": $last_name, "middleName": $middle_name, "mobile": $mobile, "otp": $otp, "password": $password, "profilePhoto": $profile_photo, "restrictions": $restrictions, "txnId": $txn_id, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Health ID using pre-verified Aadhaar & Mobile.
#
# POST /v1/registration/aadhaar/createHealthIdWithPreVerified
# operationId: createAadhaarAccountUsingPOST
export def "registration-aadhaar-create-health-id-with-pre-verified create-account-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --email: string
  --first-name: string
  --health-id: string
  --last-name: string
  --middle-name: string
  --password: string
  --profile-photo: string
  --txn-id: string
]: any -> record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/aadhaar/createHealthIdWithPreVerified")
  let req_body = {"email": $email, "firstName": $first_name, "healthId": $health_id, "lastName": $last_name, "middleName": $middle_name, "password": $password, "profilePhoto": $profile_photo, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate Mobile OTP for verification.
#
# POST /v1/registration/aadhaar/generateMobileOTP
# operationId: generateMobileOTPForTxnUsingPOST
export def "registration-aadhaar-generate-mobile-otp create-for-txn-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --mobile: string
  --txn-id: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/aadhaar/generateMobileOTP")
  let req_body = {"mobile": $mobile, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate Aadhaar OTP on registrered mobile number
#
# POST /v1/registration/aadhaar/generateOtp
# operationId: generateAadharOTPUsingPOST
export def "registration-aadhaar-generate-otp create-aadhar-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --aadhaar: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/aadhaar/generateOtp")
  let req_body = {"aadhaar": $aadhaar} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Resend Aadhaar OTP on registrered mobile number to create Health ID.
#
# POST /v1/registration/aadhaar/resendAadhaarOtp
# operationId: resendAadharOTPUsingPOST
export def "registration-aadhaar-resend-aadhaar-otp create-aadhar-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  txn_id: string
]: any -> record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/aadhaar/resendAadhaarOtp")
  let req_body = {"txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search health id number using aadhar.
#
# POST /v1/registration/aadhaar/search/aadhar
# operationId: getHealthIdNumbersByAadharUsingPOST
export def "registration-aadhaar-search-aadhar get-health-numbers-by-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --aadhaar: string
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/aadhaar/search/aadhar")
  let req_body = {"aadhaar": $aadhaar} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify Aadhaar using biometrics.
#
# POST /v1/registration/aadhaar/verifyBio
# operationId: verifyAadharBioUsingPOST
export def "registration-aadhaar-verify-bio create-aadhar-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --aadhaar: string
  --bio-type: string
  --pid: string
  --restrictions: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/aadhaar/verifyBio")
  let req_body = {"aadhaar": $aadhaar, "bioType": $bio_type, "pid": $pid, "restrictions": $restrictions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify Mobile OTP in an existing transaction.
#
# POST /v1/registration/aadhaar/verifyMobileOTP
# operationId: verifyMobileOTPForTxnUsingPOST
export def "registration-aadhaar-verify-mobile-otp create-for-txn-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --otp: string
  --txn-id: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/aadhaar/verifyMobileOTP")
  let req_body = {"otp": $otp, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify Aadhaar OTP and continue for mobile verification.
#
# POST /v1/registration/aadhaar/verifyOTP
# operationId: verifyAadharOTPOnlyUsingPOST
export def "registration-aadhaar-verify-otp create-aadhar-only-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --otp: string
  --restrictions: string
  --txn-id: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/aadhaar/verifyOTP")
  let req_body = {"otp": $otp, "restrictions": $restrictions, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Health ID with verified mobile token
#
# POST /v1/registration/mobile/createHealthId
# operationId: verifyUserViaMobileUsingPOST
export def "registration-mobile-create-health-id verify-user-via-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --address: string
  --day-of-birth: string
  --district-code: string
  --email: string
  --first-name: string
  --gender: string
  --health-id: string
  --last-name: string
  --middle-name: string
  --month-of-birth: string
  --name: string
  --password: string
  --pincode: int # format: int32
  --profile-photo: string
  --restrictions: string
  --state-code: string
  --subdistrict-code: string
  --body-token: string
  --town-code: string
  txn_id: string
  --village-code: string
  --ward-code: string
  --year-of-birth: string
]: any -> record<authMethods: list<string>, dayOfBirth: string, districtCode: string, districtName: string, email: string, firstName: string, gender: string, healthId: string, healthIdNumber: string, kycPhoto: string, lastName: string, middleName: string, mobile: string, monthOfBirth: string, name: string, new: bool, stateCode: string, stateName: string, tags: record, token: string, yearOfBirth: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/mobile/createHealthId")
  let req_body = {"address": $address, "dayOfBirth": $day_of_birth, "districtCode": $district_code, "email": $email, "firstName": $first_name, "gender": $gender, "healthId": $health_id, "lastName": $last_name, "middleName": $middle_name, "monthOfBirth": $month_of_birth, "name": $name, "password": $password, "pincode": $pincode, "profilePhoto": $profile_photo, "restrictions": $restrictions, "stateCode": $state_code, "subdistrictCode": $subdistrict_code, "token": $body_token, "townCode": $town_code, "txnId": $txn_id, "villageCode": $village_code, "wardCode": $ward_code, "yearOfBirth": $year_of_birth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate Mobile OTP to start registration
#
# POST /v1/registration/mobile/generateOtp
# operationId: generateMobileOTPUsingPOST_1
export def "registration-mobile-generate-otp create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --mobile: string
]: any -> record<txnId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/mobile/generateOtp")
  let req_body = {"mobile": $mobile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Resend Mobile OTP for Health ID registration
#
# POST /v1/registration/mobile/resendOtp
# operationId: resentOtpUsingPOST
export def "registration-mobile-resend-otp create-resent-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  txn_id: string
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/mobile/resendOtp")
  let req_body = {"txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify Mobile OTP sent as part of registration transaction.
#
# POST /v1/registration/mobile/verifyOtp
# operationId: verifyMobileOTPUsingPOST
export def "registration-mobile-verify-otp create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --otp: string
  --txn-id: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registration/mobile/verifyOtp")
  let req_body = {"otp": $otp, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search a user by Health IDs.
#
# POST /v1/search/existsByHealthId
# operationId: searchUserByUseridUsingPOST
export def "search-exists-by-health-id create-user-userid-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --health-id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/search/existsByHealthId")
  let req_body = {"healthId": $health_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search a user by Health ID Number.
#
# POST /v1/search/searchByHealthId
# operationId: searchUserByAccountUsingPOST
export def "search-search-by-health-id create-user-account-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --health-id: string
]: any -> record<authMethods: list<string>, healthId: string, healthIdNumber: string, name: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/search/searchByHealthId")
  let req_body = {"healthId": $health_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search users with a mobile number.
#
# POST /v1/search/searchByMobile
# operationId: searchUserByMobileUsingPOST
export def "search-search-by-mobile create-user-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string
  --gender: string
  --mobile: string
  --name: string
  --year-of-birth: string
]: any -> record<authMethods: list<string>, healthId: string, healthIdNumber: string, name: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/search/searchByMobile")
  let req_body = {"gender": $gender, "mobile": $mobile, "name": $name, "yearOfBirth": $year_of_birth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
