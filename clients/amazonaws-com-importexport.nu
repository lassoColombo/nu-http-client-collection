# Auto-generated client for AWS Import/Export v2010-06-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/importexport/2010-06-01/openapi.json
# Auth: --token flag or $env.AWS_IMPORT_EXPORT_TOKEN

const BASE_URL = "http://importexport.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_IMPORT_EXPORT_TOKEN | default "" }
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

def base-url-completer [] { ["http://importexport.amazonaws.com" "https://importexport.amazonaws.com" "http://importexport.cn-north-1.amazonaws.com.cn" "http://importexport.cn-northwest-1.amazonaws.com.cn" "https://importexport.cn-north-1.amazonaws.com.cn" "https://importexport.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def operation-completer [] { ["CancelJob"] }
def action-completer [] { ["CancelJob"] }
def version-completer [] { ["2010-06-01"] }
def job-type-completer [] { ["Export" "Import"] }
def operation-completer-1 [] { ["CreateJob"] }
def action-completer-1 [] { ["CreateJob"] }
def operation-completer-2 [] { ["GetShippingLabel"] }
def action-completer-2 [] { ["GetShippingLabel"] }
def operation-completer-3 [] { ["GetStatus"] }
def action-completer-3 [] { ["GetStatus"] }
def operation-completer-4 [] { ["ListJobs"] }
def action-completer-4 [] { ["ListJobs"] }
def operation-completer-5 [] { ["UpdateJob"] }
def action-completer-5 [] { ["UpdateJob"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api get-cancel-job" } } | get name | first)
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

# This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
#
# GET /
# operationId: GET_CancelJob
export def "api get-cancel-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --job-id: string
  --api-version: string
  --operation: string@operation-completer
  --action-2: string@action-completer #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<Success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "JobId" $job_id "scalar") (serialize-qp "APIVersion" $api_version "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "JobId": $job_id, "APIVersion": $api_version, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
#
# POST /
# operationId: POST_CancelJob
export def "api create-cancel-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --operation: string@operation-completer
  --action-2: string@action-completer #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<Success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
#
# GET /
# operationId: GET_CreateJob
export def "api get-create-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --job-type: string@job-type-completer
  --manifest: string
  --manifest-addendum: string
  --validate-only: oneof<nothing, bool>
  --api-version: string
  --operation: string@operation-completer-1
  --action-2: string@action-completer-1 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<JobId: string, JobType: string, Signature: string, SignatureFileContents: string, WarningMessage: string, ArtifactList: table<Description: string, URL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "JobType" $job_type "scalar") (serialize-qp "Manifest" $manifest "scalar") (serialize-qp "ManifestAddendum" $manifest_addendum "scalar") (serialize-qp "ValidateOnly" $validate_only "scalar") (serialize-qp "APIVersion" $api_version "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "JobType": $job_type, "Manifest": $manifest, "ManifestAddendum": $manifest_addendum, "ValidateOnly": $validate_only, "APIVersion": $api_version, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
#
# POST /
# operationId: POST_CreateJob
export def "api create-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --operation: string@operation-completer-1
  --action-2: string@action-completer-1 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<JobId: string, JobType: string, Signature: string, SignatureFileContents: string, WarningMessage: string, ArtifactList: table<Description: string, URL: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
#
# GET /
# operationId: GET_GetShippingLabel
export def "api get-shipping-label" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --job-ids: list
  --name: string
  --company: string
  --phone-number: string
  --country: string
  --state-or-province: string
  --city: string
  --postal-code: string
  --street1: string
  --street2: string
  --street3: string
  --api-version: string
  --operation: string@operation-completer-2
  --action-2: string@action-completer-2 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<ShippingLabelURL: string, Warning: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "jobIds" $job_ids "multi") (serialize-qp "name" $name "scalar") (serialize-qp "company" $company "scalar") (serialize-qp "phoneNumber" $phone_number "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "stateOrProvince" $state_or_province "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "postalCode" $postal_code "scalar") (serialize-qp "street1" $street1 "scalar") (serialize-qp "street2" $street2 "scalar") (serialize-qp "street3" $street3 "scalar") (serialize-qp "APIVersion" $api_version "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "jobIds": $job_ids, "name": $name, "company": $company, "phoneNumber": $phone_number, "country": $country, "stateOrProvince": $state_or_province, "city": $city, "postalCode": $postal_code, "street1": $street1, "street2": $street2, "street3": $street3, "APIVersion": $api_version, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
#
# POST /
# operationId: POST_GetShippingLabel
export def "api create-get-shipping-label" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --operation: string@operation-completer-2
  --action-2: string@action-completer-2 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<ShippingLabelURL: string, Warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
#
# GET /
# operationId: GET_GetStatus
export def "api get-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --job-id: string
  --api-version: string
  --operation: string@operation-completer-3
  --action-2: string@action-completer-3 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<JobId: string, JobType: string, LocationCode: string, LocationMessage: string, ProgressCode: string, ProgressMessage: string, Carrier: string, TrackingNumber: string, LogBucket: string, LogKey: string, ErrorCount: int, Signature: string, SignatureFileContents: string, CurrentManifest: string, CreationDate: string, ArtifactList: table<Description: string, URL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "JobId" $job_id "scalar") (serialize-qp "APIVersion" $api_version "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "JobId": $job_id, "APIVersion": $api_version, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
#
# POST /
# operationId: POST_GetStatus
export def "api create-get-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --operation: string@operation-completer-3
  --action-2: string@action-completer-3 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<JobId: string, JobType: string, LocationCode: string, LocationMessage: string, ProgressCode: string, ProgressMessage: string, Carrier: string, TrackingNumber: string, LogBucket: string, LogKey: string, ErrorCount: int, Signature: string, SignatureFileContents: string, CurrentManifest: string, CreationDate: string, ArtifactList: table<Description: string, URL: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
#
# GET /
# operationId: GET_ListJobs
export def "api get-list-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --max-jobs: int
  --marker: string
  --api-version: string
  --operation: string@operation-completer-4
  --action-2: string@action-completer-4 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<Jobs: table<JobId: string, CreationDate: string, IsCanceled: bool, JobType: string>, IsTruncated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "MaxJobs" $max_jobs "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "APIVersion" $api_version "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "MaxJobs": $max_jobs, "Marker": $marker, "APIVersion": $api_version, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
#
# POST /
# operationId: POST_ListJobs
export def "api create-list-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --max-jobs: string # Pagination limit
  --marker: string # Pagination token
  --operation: string@operation-completer-4
  --action-2: string@action-completer-4 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<Jobs: table<JobId: string, CreationDate: string, IsCanceled: bool, JobType: string>, IsTruncated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "MaxJobs" $max_jobs "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "MaxJobs": $max_jobs, "Marker": $marker, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
#
# GET /
# operationId: GET_UpdateJob
export def "api get-update-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --job-id: string
  --manifest: string
  --job-type: string@job-type-completer
  --validate-only: oneof<nothing, bool>
  --api-version: string
  --operation: string@operation-completer-5
  --action-2: string@action-completer-5 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<Success: bool, WarningMessage: string, ArtifactList: table<Description: string, URL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "JobId" $job_id "scalar") (serialize-qp "Manifest" $manifest "scalar") (serialize-qp "JobType" $job_type "scalar") (serialize-qp "ValidateOnly" $validate_only "scalar") (serialize-qp "APIVersion" $api_version "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "JobId": $job_id, "Manifest": $manifest, "JobType": $job_type, "ValidateOnly": $validate_only, "APIVersion": $api_version, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
#
# POST /
# operationId: POST_UpdateJob
export def "api create-update-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --operation: string@operation-completer-5
  --action-2: string@action-completer-5 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<Success: bool, WarningMessage: string, ArtifactList: table<Description: string, URL: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Operation" $operation "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Operation": $operation, "Action": $action_2, "Version": $version_2} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
