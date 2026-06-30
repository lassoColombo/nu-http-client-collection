# Auto-generated client for VisageCloud v1.1
# Source: https://api.apis.guru/v2/specs/visagecloud.com/1.1/swagger.json
# Auth: --token flag or $env.VISAGECLOUD_TOKEN

const BASE_URL = "https://visagecloud.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o VISAGECLOUD_TOKEN | default "" }
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://visagecloud.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def algorithm-version-completer [] { ["V1" "V2"] }
def attribute-filters-completer [] { ["AGE_GROUP_FILTER" "GENDER_FILTER" "NO_FILTER"] }
def purposes-completer [] { ["ATTRIBUTES" "FEATURES" "LANDMARKS"] }
def method-completer [] { ["INGESTION_ENDPOINT" "WEBRTC_PULL" "WEBRTC_PUSH"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rest-v1-1-account-account get-by-access-key-using" } } | get name | first)
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

# Get account information by accessKey and secretKey
#
# GET /rest/v1.1/account/account
# operationId: getAccountByAccessKeyUsingGET
export def "rest-v1-1-account-account get-by-access-key-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # accessKey
  --secret-key: string # secretKey
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/account/account" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get billing information by accessKey and secretKey
#
# GET /rest/v1.1/account/billing
# operationId: getBillingPerAccountUsingGET
export def "rest-v1-1-account-billing get-per-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # accessKey
  --secret-key: string # secretKey
  --start-date-time: string # startDateTime (format: date-time)
  --end-date-time: string # endDateTime (format: date-time)
  --date-template: string # dateTemplate
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "dateTemplate" $date_template "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/account/billing" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "startDateTime": $start_date_time, "endDateTime": $end_date_time, "dateTemplate": $date_template} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Change password for an account using old password
#
# POST /rest/v1.1/account/changePassword
# operationId: changePasswordUsingPOST
export def "rest-v1-1-account-change-password create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # email
  --old-password: string # oldPassword
  --new-password: string # newPassword
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "oldPassword" $old_password "scalar") (serialize-qp "newPassword" $new_password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/account/changePassword" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"email": $email, "oldPassword": $old_password, "newPassword": $new_password} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Get account information including accessKey and secretKey by email and password
#
# POST /rest/v1.1/account/login
# operationId: loginWithEmailUsingPOST
export def "rest-v1-1-account-login create-with-email-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # email
  --password: string # password
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/account/login" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"email": $email, "password": $password} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Compare several faces identified by faceHash, without depending on mapping faces to profiles
#
# GET /rest/v1.1/analysis/compare
# operationId: compareFacesUsingGET
export def "rest-v1-1-analysis-compare get-faces-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --face-hashes: list<string> # The IDs of the faces which you want compared, comma-separated
  --show-details: oneof<nothing, bool> # Show details (default: false)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "faceHashes" $face_hashes "multi") (serialize-qp "showDetails" $show_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/compare" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "faceHashes": $face_hashes, "showDetails": $show_details} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Perform detection on a given picture or picture URL
#
# POST /rest/v1.1/analysis/detection
# operationId: performAnalysisUsingPOST
export def "rest-v1-1-analysis-detection create-perform-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --store-analysis-picture: oneof<nothing, bool> # Boolean value indicating whether you want the picture of the analysis to be stored for later retrieval (default: true)
  --store-face-pictures: oneof<nothing, bool> # Boolean value indicating whether you want the faces inside the picture to be stored for later retrieval (default: true)
  --store-result: oneof<nothing, bool> # Boolean value indicating whether you want the result of the analysis to be stored (default: true)
  --retention-time: int # How many seconds the results should be retained in stoarage? (format: int32)
  --picture-url: string # The URL of the picture, assuming it is served by a third party server. Server should be accesible from the Internet or through another netwoek by VisageCloud infrastructure
  --algorithm-version: string@algorithm-version-completer # Algorithm version (V2 is more performant but not backward compatible) (default: V2)
  --auto-rotate: oneof<nothing, bool> # Auto-rotate to find flipped or rotate faces (default: false)
  --skip-exif: oneof<nothing, bool> # Skip EXIF rotation procesing (default: false)
  --wait-for-picture-upload: oneof<nothing, bool> # Waits until the picture is successfully uploaded, before returning the response back the the client (default: false)
  --filters: list<string> # [For advanced users only] Change feature filters for robustness of feature extraction. Tweaking this parameter may affect per
  --options: string # [For advanced users only] Options for preprocessing of image.
  --picture: string # The multipart/form-data version of the image, in case a direct upload is used. At least one of picture or pictureURL must be present
]: any -> record<message: string, payload: record, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "storeAnalysisPicture" $store_analysis_picture "scalar") (serialize-qp "storeFacePictures" $store_face_pictures "scalar") (serialize-qp "storeResult" $store_result "scalar") (serialize-qp "retentionTime" $retention_time "scalar") (serialize-qp "pictureURL" $picture_url "scalar") (serialize-qp "algorithmVersion" $algorithm_version "scalar") (serialize-qp "autoRotate" $auto_rotate "scalar") (serialize-qp "skipEXIF" $skip_exif "scalar") (serialize-qp "waitForPictureUpload" $wait_for_picture_upload "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "options" $options "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/detection" $qp $auth.query)
  let req_body = {"picture": $picture} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "storeAnalysisPicture": $store_analysis_picture, "storeFacePictures": $store_face_pictures, "storeResult": $store_result, "retentionTime": $retention_time, "pictureURL": $picture_url, "algorithmVersion": $algorithm_version, "autoRotate": $auto_rotate, "skipEXIF": $skip_exif, "waitForPictureUpload": $wait_for_picture_upload, "filters": $filters, "options": $options} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200 201]
}

# Retrieve the last *count* operations per current account
#
# GET /rest/v1.1/analysis/listLatest
# operationId: retriveLatestUsingGET
export def "rest-v1-1-analysis-list-latest get-retrive-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --count: int # How many records to retrieve at a time (format: int32, default: 100)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/listLatest" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Perform labeled recognition on a given picture or picture URL
#
# POST /rest/v1.1/analysis/recognition
# operationId: performRecognitionUsingPOST
export def "rest-v1-1-analysis-recognition create-perform-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --store-analysis-picture: oneof<nothing, bool> # Boolean value indicating whether you want the picture of the analysis to be stored for later retrieval (default: true)
  --store-face-pictures: oneof<nothing, bool> # Boolean value indicating whether you want the faces inside the picture to be stored for later retrieval (default: true)
  --store-result: oneof<nothing, bool> # Boolean value indicating whether you want the result of the analysis to be stored (default: true)
  --retention-time: int # How many seconds the results should be retained in stoarage? (format: int32)
  --collection-id: string # Uniquely identified collection that can store multiple profiles
  --labels: list<string> # Labels associated with the given picture or picture URL
  --attribute-filters: list<string>@attribute-filters-completer # Filters that will be applied on the recognition operation
  --picture-url: string # The URL of the picture
  --algorithm-version: string@algorithm-version-completer # Algorithm version (V2 is more performant but not backward compatible) (default: V2)
  --auto-rotate: oneof<nothing, bool> # Auto-rotate to find flipped or rotate faces (default: false)
  --skip-exif-rotation-processing: oneof<nothing, bool> # Skip EXIF rotation procesing (default: false)
  --wait-for-picture-upload: oneof<nothing, bool> # Waits until the picture is successfully uploaded, before returning the response back the the client (default: false)
  --filters: list<string> # [For advanced users only] Change feature filters for robustness of feature extraction. Tweaking this parameter may affect per
  --options: string # [For advanced users only] Options for preprocessing of image.
  --picture: string # The picture itself
]: any -> record<message: string, payload: record, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "storeAnalysisPicture" $store_analysis_picture "scalar") (serialize-qp "storeFacePictures" $store_face_pictures "scalar") (serialize-qp "storeResult" $store_result "scalar") (serialize-qp "retentionTime" $retention_time "scalar") (serialize-qp "collectionId" $collection_id "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "attributeFilters" $attribute_filters "multi") (serialize-qp "pictureURL" $picture_url "scalar") (serialize-qp "algorithmVersion" $algorithm_version "scalar") (serialize-qp "autoRotate" $auto_rotate "scalar") (serialize-qp "skipEXIF rotation processing" $skip_exif_rotation_processing "scalar") (serialize-qp "waitForPictureUpload" $wait_for_picture_upload "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "options" $options "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/recognition" $qp $auth.query)
  let req_body = {"picture": $picture} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "storeAnalysisPicture": $store_analysis_picture, "storeFacePictures": $store_face_pictures, "storeResult": $store_result, "retentionTime": $retention_time, "collectionId": $collection_id, "labels": $labels, "attributeFilters": $attribute_filters, "pictureURL": $picture_url, "algorithmVersion": $algorithm_version, "autoRotate": $auto_rotate, "skipEXIF rotation processing": $skip_exif_rotation_processing, "waitForPictureUpload": $wait_for_picture_upload, "filters": $filters, "options": $options} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200 201]
}

# Retrieve a complete analysis object including both detection and recognition information
#
# GET /rest/v1.1/analysis/retrieve
# operationId: retrieveAnalysisUsingGET
export def "rest-v1-1-analysis-retrieve get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --analysis-id: string # The ID of the analysis for which the data will be retrieved
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "analysisId" $analysis_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analysis/retrieve" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "analysisId": $analysis_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Count individuals in streams or collections
#
# POST /rest/v1.1/analytics/counting
# operationId: counterUsingPOST
export def "rest-v1-1-analytics-counting create-counter-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --collection-ids: list<string> # Collection ids
  --stream-ids: list<string> # Stream Ids
  --start-date-time: string # startDateTime (format: date-time)
  --end-date-time: string # endDateTime (format: date-time)
  --visit-duration: int # visitDuration (format: int64, default: 3600000)
  --max-iterations: int # maxIterations (format: int32, default: 1)
  --max-batch-iterations: int # maxBatchIterations (format: int32, default: 1)
  --min-neighbors-merged-per-iteration: int # minNeighborsMergedPerIteration (format: int32, default: 5)
  --merging-step: float # mergingStep (format: double, default: 1)
  --shuffling: oneof<nothing, bool> # shuffling (default: false)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionIds" $collection_ids "multi") (serialize-qp "streamIds" $stream_ids "multi") (serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "visitDuration" $visit_duration "scalar") (serialize-qp "maxIterations" $max_iterations "scalar") (serialize-qp "maxBatchIterations" $max_batch_iterations "scalar") (serialize-qp "minNeighborsMergedPerIteration" $min_neighbors_merged_per_iteration "scalar") (serialize-qp "mergingStep" $merging_step "scalar") (serialize-qp "shuffling" $shuffling "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analytics/counting" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionIds": $collection_ids, "streamIds": $stream_ids, "startDateTime": $start_date_time, "endDateTime": $end_date_time, "visitDuration": $visit_duration, "maxIterations": $max_iterations, "maxBatchIterations": $max_batch_iterations, "minNeighborsMergedPerIteration": $min_neighbors_merged_per_iteration, "mergingStep": $merging_step, "shuffling": $shuffling} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Show audience (based on number of occurrences of each person) breakdown per declared attribute (age, gender).
#
# POST /rest/v1.1/analytics/presence/timeseries
# operationId: presenceTimeseriesUsingPOST
export def "rest-v1-1-analytics-presence-timeseries create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --stream-ids: list<string> # Stream Ids
  --start-date-time: string # startDateTime (format: date-time)
  --end-date-time: string # endDateTime (format: date-time)
  --step: int # step (format: int64, default: 3600)
  --attributes: list<string> # attributes
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "streamIds" $stream_ids "multi") (serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "step" $step "scalar") (serialize-qp "attributes" $attributes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analytics/presence/timeseries" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "streamIds": $stream_ids, "startDateTime": $start_date_time, "endDateTime": $end_date_time, "step": $step, "attributes": $attributes} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Show presence (based on number of occurences of each face) breakdown per declared attribute (age, gender)
#
# POST /rest/v1.1/analytics/presence/total
# operationId: presenceTotalUsingPOST
export def "rest-v1-1-analytics-presence-total create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --stream-ids: list<string> # Stream Ids
  --start-date-time: string # startDateTime (format: date-time)
  --end-date-time: string # endDateTime (format: date-time)
  --attributes: list<string> # attributes
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "streamIds" $stream_ids "multi") (serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "attributes" $attributes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/analytics/presence/total" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "streamIds": $stream_ids, "startDateTime": $start_date_time, "endDateTime": $end_date_time, "attributes": $attributes} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Delete existing classifier
#
# DELETE /rest/v1.1/classifier/svm
# operationId: removeClassiferUsingDELETE
export def "rest-v1-1-classifier-svm delete-classifer-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --id: string # The id of the classifier that will be removed
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/classifier/svm" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Get classifier full
#
# GET /rest/v1.1/classifier/svm
# operationId: getClassiferFullUsingGET
export def "rest-v1-1-classifier-svm get-classifer-full-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --id: string # The id of the classifier that you want the status for
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/classifier/svm" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new SVM classifier with given name
#
# POST /rest/v1.1/classifier/svm
# operationId: addSVMClassifierUsingPOST
export def "rest-v1-1-classifier-svm create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --name: string # The name of the SVM classifier that will be created
  --collection-ids: list<string> # Collection ids
  --preprocessor: string # Preprocessor (default: FeaturePreprocessor)
  --classification-attribute-name: string # Classification attribute name
  --consider-view-points: oneof<nothing, bool> # Consider view point (default: false)
  --seed: int # Seed for divididing training and evaluation sets (format: int32, default: 179425537)
  --training-ratio: float # Training ratio (format: double, default: 0.8)
  --probability-parameter: int # Probability parameter (format: int32, default: 1)
  --gamma-parameter: float # Gamma parameter (format: double, default: 0.5)
  --nu-parameter: float # Nu parameter (format: double, default: 0.25)
  --c-parameter: float # c parameter (format: double, default: 1)
  --svm-type-parameter: int # SVM type parameter (format: int32, default: 0)
  --kernel-type-parameter: int # Kernel type parameter (format: int32, default: 0)
  --cache-size-parameter: float # Cache size parameter (format: double, default: 500)
  --eps-parameter: float # Eps parameter (format: double, default: 0.001)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "collectionIds" $collection_ids "multi") (serialize-qp "preprocessor" $preprocessor "scalar") (serialize-qp "classificationAttributeName" $classification_attribute_name "scalar") (serialize-qp "considerViewPoints" $consider_view_points "scalar") (serialize-qp "seed" $seed "scalar") (serialize-qp "trainingRatio" $training_ratio "scalar") (serialize-qp "probabilityParameter" $probability_parameter "scalar") (serialize-qp "gammaParameter" $gamma_parameter "scalar") (serialize-qp "nuParameter" $nu_parameter "scalar") (serialize-qp "cParameter" $c_parameter "scalar") (serialize-qp "svmTypeParameter" $svm_type_parameter "scalar") (serialize-qp "kernelTypeParameter" $kernel_type_parameter "scalar") (serialize-qp "cacheSizeParameter" $cache_size_parameter "scalar") (serialize-qp "epsParameter" $eps_parameter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/classifier/svm" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "name": $name, "collectionIds": $collection_ids, "preprocessor": $preprocessor, "classificationAttributeName": $classification_attribute_name, "considerViewPoints": $consider_view_points, "seed": $seed, "trainingRatio": $training_ratio, "probabilityParameter": $probability_parameter, "gammaParameter": $gamma_parameter, "nuParameter": $nu_parameter, "cParameter": $c_parameter, "svmTypeParameter": $svm_type_parameter, "kernelTypeParameter": $kernel_type_parameter, "cacheSizeParameter": $cache_size_parameter, "epsParameter": $eps_parameter} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Get classifer status
#
# GET /rest/v1.1/classifier/svm/status
# operationId: getClassiferStatusUsingGET
export def "rest-v1-1-classifier-svm-status get-classifer-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --id: string # The id of the classifier that you want the status for
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/classifier/svm/status" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve all collections
#
# GET /rest/v1.1/collection/
# operationId: getAllCollectionsUsingGET
export def "rest-v1-1-collection get-list-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new empty collection with given name
#
# POST /rest/v1.1/collection/
# operationId: addCollectionUsingPOST
export def "rest-v1-1-collection create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  access_key: string # The accessKey provided by VisageCloud
  secret_key: string # The secretKey provided by VisageCloud
  name: string # The name of the collection that will be created
  --preload: oneof<nothing, bool> # Defined whether to preload collection
  --evictable: oneof<nothing, bool> # Defined whether the collection can be evicted
  --purposes: list@purposes-completer # The newly declared purposes of the collection
]: any -> record<message: string, payload: record, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/v1.1/collection/" $auth.query)
  let req_body = {"accessKey": $access_key, "secretKey": $secret_key, "name": $name, "preload": $preload, "evictable": $evictable, "purposes": $purposes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200 201]
}

# Retrieve all collections
#
# GET /rest/v1.1/collection/all
# DEPRECATED
# operationId: getAllCollections2UsingGET
@deprecated
export def "rest-v1-1-collection-all get-collections2-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/all" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete existing collection with associated profiles and faces.
#
# DELETE /rest/v1.1/collection/collection
# DEPRECATED
# operationId: deleteCollection2UsingDELETE
@deprecated
export def "rest-v1-1-collection-collection delete-collection2-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --collection-id: string # The id of the collection that will be removed
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/collection" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Retrieve existing collection content
#
# GET /rest/v1.1/collection/collection
# DEPRECATED
# operationId: getCollection2UsingGET
@deprecated
export def "rest-v1-1-collection-collection get-collection2-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --collection-id: string # The id of the collection for which the data will be retrieved
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/collection" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new empty collection with given name
#
# POST /rest/v1.1/collection/collection
# DEPRECATED
# operationId: addCollection2UsingPOST
@deprecated
export def "rest-v1-1-collection-collection create-collection2-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --collection-name: string # The name of the collection that will be created
  --preload: oneof<nothing, bool> # Defined whether to preload collection (default: false)
  --evictable: oneof<nothing, bool> # Defined whether the collection can be evicted (default: true)
  --purposes: list<string>@purposes-completer # The newly declared purposes of the collection
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionName" $collection_name "scalar") (serialize-qp "preload" $preload "scalar") (serialize-qp "evictable" $evictable "scalar") (serialize-qp "purposes" $purposes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/collection" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionName": $collection_name, "preload": $preload, "evictable": $evictable, "purposes": $purposes} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Retrieve collection content for data analysis.
#
# GET /rest/v1.1/collection/export/csv
# operationId: exportCSVUsingGET
export def "rest-v1-1-collection-export-csv get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --collection-id: string # The id of the collection for which the data will be retrieved
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/export/csv" $qp $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Change purpose of existing collection
#
# PUT /rest/v1.1/collection/purpose
# DEPRECATED
# operationId: repurposeCollectionUsingPUT
@deprecated
export def "rest-v1-1-collection-purpose update-repurpose-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --collection-id: string # The id of the collection for which the data will be retrieved
  --purposes: list<string>@purposes-completer # The newly declared purposes of the collection
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionId" $collection_id "scalar") (serialize-qp "purposes" $purposes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/collection/purpose" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionId": $collection_id, "purposes": $purposes} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200 201]
}

# Delete existing collection with associated profiles and faces.
#
# DELETE /rest/v1.1/collection/{id}
# operationId: deleteCollectionUsingDELETE
export def "rest-v1-1-collection delete-using" [
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
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/v1.1/collection/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Retrieve existing collection content
#
# GET /rest/v1.1/collection/{id}
# operationId: getCollectionUsingGET
export def "rest-v1-1-collection get-using" [
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
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/v1.1/collection/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an existing collection with a given id
#
# PATCH /rest/v1.1/collection/{id}
# operationId: updateCollectionUsingPATCH
export def "rest-v1-1-collection update-using" [
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
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --name: string # The name of the collection that will be updated
  --purposes: list<string>@purposes-completer # The newly declared purposes of the collection
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "purposes" $purposes "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/v1.1/collection/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "name": $name, "purposes": $purposes} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200 204]
}

# Update an existing collection with a given id
#
# POST /rest/v1.1/collection/{id}
# DEPRECATED
# operationId: updateCollection2UsingPOST
@deprecated
export def "rest-v1-1-collection update-collection2-using-create" [
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
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --name: string # The name of the collection that will be updated
  --purposes: list<string>@purposes-completer # The newly declared purposes of the collection
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "purposes" $purposes "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/v1.1/collection/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "name": $name, "purposes": $purposes} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Gets all the profiles associated to a collection
#
# GET /rest/v1.1/collection/{id}/profile
# operationId: getAllCollectionProfilesUsingGET
export def "rest-v1-1-collection-profile get-list-using" [
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
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/v1.1/collection/{id}/profile") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Removes classification attributes from a profile
#
# DELETE /rest/v1.1/profile/classificationAttributes
# DEPRECATED
# operationId: removeClassificationAttributesFromProfileUsingDELETE
@deprecated
export def "rest-v1-1-profile-classification-attributes delete-from-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --profile-id: string # The profile associated with the classification attributes
  --collection-id: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "profileId" $profile_id "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/classificationAttributes" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "profileId": $profile_id, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets classification attributes from a profile
#
# GET /rest/v1.1/profile/classificationAttributes
# DEPRECATED
# operationId: getClassificationAttributesFromProfileUsingGET
@deprecated
export def "rest-v1-1-profile-classification-attributes get-from-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --profile-id: string # The profile associated with the classification attributes
  --collection-id: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "profileId" $profile_id "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/classificationAttributes" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "profileId": $profile_id, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Maps classification attributes to a profile
#
# PUT /rest/v1.1/profile/classificationAttributes
# DEPRECATED
# operationId: mapClassificationAttributesToProfileUsingPUT
@deprecated
export def "rest-v1-1-profile-classification-attributes update-map-to-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --profile-id: string # The profile associated with the classification attributes
  --collection-id: string # The collection that contains the profile
  --classification-attributes: string # Comma separated key:value classification attributes
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "profileId" $profile_id "scalar") (serialize-qp "collectionId" $collection_id "scalar") (serialize-qp "classificationAttributes" $classification_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/classificationAttributes" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "profileId": $profile_id, "collectionId": $collection_id, "classificationAttributes": $classification_attributes} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200 201]
}

# Gets the enrollment status of a profile: information on whether it is suitable for authentication.
#
# GET /rest/v1.1/profile/enrollmentStatus
# operationId: getProfileEnrollmentStatusUsingGET
export def "rest-v1-1-profile-enrollment-status get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --profile-id: string # The profile that contains the faces
  --collection-id: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "profileId" $profile_id "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/enrollmentStatus" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "profileId": $profile_id, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Removes (unmaps) a list of faces, identified by faceHashes, from a profile, identified by profileId
#
# DELETE /rest/v1.1/profile/map
# operationId: removeFacesFromProfileUsingDELETE
export def "rest-v1-1-profile-map delete-faces-from-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --face-hashes: string # Comma separated face hashes, that will be removed from a profile
  --profile-id: string # The profile that contains the face
  --collection-id: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "faceHashes" $face_hashes "scalar") (serialize-qp "profileId" $profile_id "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/map" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "faceHashes": $face_hashes, "profileId": $profile_id, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets all the faceHashes associated to a profile
#
# GET /rest/v1.1/profile/map
# operationId: getFacesFromProfileUsingGET
export def "rest-v1-1-profile-map get-faces-from-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --profile-id: string # The profile that contains the faces
  --collection-id: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "profileId" $profile_id "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/map" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "profileId": $profile_id, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds (maps) a list of faces, identified by faceHashes, to a profile, identified by profileId
#
# POST /rest/v1.1/profile/map
# operationId: mapFacesToProfileUsingPOST
export def "rest-v1-1-profile-map create-faces-to-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --face-hashes: string # Comma separated face hashes, that will be associated to a profile
  --profile-id: string # The profile that will store the face
  --collection-id: string # The collection that contains the profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "faceHashes" $face_hashes "scalar") (serialize-qp "profileId" $profile_id "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/map" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "faceHashes": $face_hashes, "profileId": $profile_id, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Deletes a profile and unmaps all its faces
#
# DELETE /rest/v1.1/profile/profile
# DEPRECATED
# operationId: deleteProfile2UsingDELETE
@deprecated
export def "rest-v1-1-profile-profile delete-profile2-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --collection-id: string # Uniquely identified collection that can store multiple profiles
  --profile-id: string # The profile id (provide this if you don't have the externalId
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionId" $collection_id "scalar") (serialize-qp "profileId" $profile_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/profile" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionId": $collection_id, "profileId": $profile_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Creates a new profile with no faces associated to it (empty profile)
#
# POST /rest/v1.1/profile/profile
# operationId: addProfileUsingPOST
export def "rest-v1-1-profile-profile create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --collection-id: string # Uniquely identified collection that can store multiple profiles
  --external-id: string # External reference to additional information you don’t want to share with VisageCloud
  --screen-name: string # Human-readable label for the profile
  --labels: list<string> # Allows you to do finer filtering in face recognition
  --classification-attributes: string # Comma separated key:value classification attributes
  --details: string # Comma separated key:value details of profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionId" $collection_id "scalar") (serialize-qp "externalId" $external_id "scalar") (serialize-qp "screenName" $screen_name "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "classificationAttributes" $classification_attributes "scalar") (serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/profile/profile" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionId": $collection_id, "externalId": $external_id, "screenName": $screen_name, "labels": $labels, "classificationAttributes": $classification_attributes, "details": $details} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Deletes a profile and unmaps all its faces
#
# DELETE /rest/v1.1/profile/{id}
# operationId: deleteProfileUsingDELETE
export def "rest-v1-1-profile delete-using" [
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
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --collection-id: string # Uniquely identified collection that can store multiple profiles
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionId" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/v1.1/profile/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionId": $collection_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Retrieves a profile
#
# GET /rest/v1.1/profile/{id}
# operationId: getProfileUsingGET
export def "rest-v1-1-profile get-using" [
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
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --collection-id: string # Uniquely identified collection that can store multiple profiles
  --with-faces: string # Retrieves the profile with all its associated faces (default: false)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionId" $collection_id "scalar") (serialize-qp "withFaces" $with_faces "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/v1.1/profile/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionId": $collection_id, "withFaces": $with_faces} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an existing profile with a given id
#
# PATCH /rest/v1.1/profile/{id}
# operationId: updateProfileUsingPATCH
export def "rest-v1-1-profile update-using" [
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
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --collection-id: string # Uniquely identified collection that can store multiple profiles
  --external-id: string # External reference to additional information you don’t want to share with VisageCloud
  --screen-name: string # Human-readable label for the profile
  --labels: list<string> # Allows you to do finer filtering in face recognition
  --classification-attributes: string # Comma separated key:value classification attributes
  --details: string # Comma separated key:value details of profile
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "collectionId" $collection_id "scalar") (serialize-qp "externalId" $external_id "scalar") (serialize-qp "screenName" $screen_name "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "classificationAttributes" $classification_attributes "scalar") (serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/v1.1/profile/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "collectionId": $collection_id, "externalId": $external_id, "screenName": $screen_name, "labels": $labels, "classificationAttributes": $classification_attributes, "details": $details} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200 204]
}

# Show status of all streams from account
#
# GET /rest/v1.1/stream/all
# operationId: streamsByAccountUsingGET
export def "rest-v1-1-stream-all get-by-account-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/all" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get last N recognized individuals from stream
#
# GET /rest/v1.1/stream/attendance
# operationId: getLastNAttedanceUsingGET
export def "rest-v1-1-stream-attendance get-last-n-attedance-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --stream-ids: list<string> # The id of the stream for which the frames will be retrieved
  --count: int # How many frames to retrieve at a time (format: int32, default: 10)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "streamIds" $stream_ids "multi") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/attendance" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "streamIds": $stream_ids, "count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Cleanup frames older than specified timeframe
#
# PATCH /rest/v1.1/stream/cleanup
# operationId: cleanupStreamUsingPATCH
export def "rest-v1-1-stream-cleanup update-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --stream-id: string # The id of the stream that will be stopped
  --interval: int # Frames older than interval (seconds) will be cleaned up (format: int32)
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "streamId" $stream_id "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/cleanup" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "streamId": $stream_id, "interval": $interval} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200 204]
}

# Get individual frame image
#
# GET /rest/v1.1/stream/frameImage
# operationId: getFrameImageUsingGET
export def "rest-v1-1-stream-frame-image get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --stream-id: string # The id of the stream for which the frames will be retrieved
  --timestamp: int # Timestamp of frame to retrieve (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "streamId" $stream_id "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/frameImage" $qp $auth.query)
  let accept_val = "image/jpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "streamId": $stream_id, "timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get last processed N frames from stream
#
# GET /rest/v1.1/stream/frames
# operationId: getLastNFramesUsingGET
export def "rest-v1-1-stream-frames get-last-n-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey or readOnlyKey provided by VisageCloud
  --stream-id: string # The id of the stream for which the frames will be retrieved
  --count: int # How many frames to retrieve at a time (format: int32, default: 10)
  --collection-id: string # The collection id you want to run recognition against
  --labels: list<string> # Labels associated with the given picture or picture URL
  --attribute-filters: list<string>@attribute-filters-completer # Filters that will be applied on the recognition operation
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "streamId" $stream_id "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "collectionId" $collection_id "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "attributeFilters" $attribute_filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/frames" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "streamId": $stream_id, "count": $count, "collectionId": $collection_id, "labels": $labels, "attributeFilters": $attribute_filters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Start existing stream
#
# PATCH /rest/v1.1/stream/start
# operationId: startStreamUsingPATCH
export def "rest-v1-1-stream-start update-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --stream-id: string # The id of the stream that will be started
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "streamId" $stream_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/start" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "streamId": $stream_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200 204]
}

# Stop existing stream
#
# PATCH /rest/v1.1/stream/stop
# operationId: stopStreamUsingPATCH
export def "rest-v1-1-stream-stop update-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --stream-id: string # The id of the stream that will be stopped
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "streamId" $stream_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/stop" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "streamId": $stream_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200 204]
}

# Create new stream with given name
#
# POST /rest/v1.1/stream/stream
# operationId: addStreamUsingPOST
export def "rest-v1-1-stream-stream create-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --name: string # The name of the stream that will be created
  --url: string # The url of the stream
  --method: string@method-completer # Streaming method (default: WEBRTC_PUSH)
  --username: string # Username
  --password: string # Password
  --skip-frames-with-no-faces: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval (default: true)
  --retention-time: int # Number of seconds for frames to be kept. Default is 605000s (7 days) (format: int32, default: 605000)
  --store-original-frames: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval (default: false)
  --store-attendance-faces: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store faces clippings of the recognized faces (default: false)
  --store-attendance-frames: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store frames with a recognized face in them (default: false)
  --is-active: oneof<nothing, bool> # Boolean value indicating whether the stream is currently active or not (default: false)
  --associated-collections: list<string> # List of collection ids which will be used to measure attendance
  --attributes: string # Attributes of the stream
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "skipFramesWithNoFaces" $skip_frames_with_no_faces "scalar") (serialize-qp "retentionTime" $retention_time "scalar") (serialize-qp "storeOriginalFrames" $store_original_frames "scalar") (serialize-qp "storeAttendanceFaces" $store_attendance_faces "scalar") (serialize-qp "storeAttendanceFrames" $store_attendance_frames "scalar") (serialize-qp "isActive" $is_active "scalar") (serialize-qp "associatedCollections" $associated_collections "multi") (serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1.1/stream/stream" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "name": $name, "url": $url, "method": $method, "username": $username, "password": $password, "skipFramesWithNoFaces": $skip_frames_with_no_faces, "retentionTime": $retention_time, "storeOriginalFrames": $store_original_frames, "storeAttendanceFaces": $store_attendance_faces, "storeAttendanceFrames": $store_attendance_frames, "isActive": $is_active, "associatedCollections": $associated_collections, "attributes": $attributes} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 201]
}

# Delete existing stream
#
# DELETE /rest/v1.1/stream/{id}
# operationId: removeStreamUsingDELETE
export def "rest-v1-1-stream delete-using" [
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
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/rest/v1.1/stream/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Get an existing stream with a given ID
#
# GET /rest/v1.1/stream/{streamId}
# operationId: getStreamUsingGET
export def "rest-v1-1-stream get-using" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stream_id | is-empty) { error make --unspanned { msg: "path parameter 'streamId' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({stream_id: (encode-path-segment $stream_id)} | format pattern "/rest/v1.1/stream/{stream_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an existing stream with a given ID
#
# PATCH /rest/v1.1/stream/{streamId}
# operationId: updateStreamUsingPATCH
export def "rest-v1-1-stream update-using" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-key: string # The accessKey provided by VisageCloud
  --secret-key: string # The secretKey provided by VisageCloud
  --name: string # The name of the stream that will be updated
  --url: string # The url of the stream
  --method: string@method-completer # Streaming method
  --username: string # Username
  --password: string # Password
  --skip-frames-with-no-faces: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval
  --retention-time: int # Number of seconds for frames to be kept (format: int32)
  --store-original-frames: oneof<nothing, bool> # Boolean value indicating whether you want the original picture to be stored for later retrieval
  --store-attendance-faces: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store faces clippings of the recognized faces
  --store-attendance-frames: oneof<nothing, bool> # Boolean value indicating whether you want to store permanently store frames with a recognized face in them
  --is-active: oneof<nothing, bool> # Boolean value indicating whether the stream is currently active or not
  --associated-collections: list<string> # List of collection ids which will be used to measure attendance
  --attributes: string # Attributes of the stream
]: nothing -> record<message: string, payload: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stream_id | is-empty) { error make --unspanned { msg: "path parameter 'streamId' must be non-empty" } }
  let qp = [(serialize-qp "accessKey" $access_key "scalar") (serialize-qp "secretKey" $secret_key "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "skipFramesWithNoFaces" $skip_frames_with_no_faces "scalar") (serialize-qp "retentionTime" $retention_time "scalar") (serialize-qp "storeOriginalFrames" $store_original_frames "scalar") (serialize-qp "storeAttendanceFaces" $store_attendance_faces "scalar") (serialize-qp "storeAttendanceFrames" $store_attendance_frames "scalar") (serialize-qp "isActive" $is_active "scalar") (serialize-qp "associatedCollections" $associated_collections "multi") (serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({stream_id: (encode-path-segment $stream_id)} | format pattern "/rest/v1.1/stream/{stream_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"accessKey": $access_key, "secretKey": $secret_key, "name": $name, "url": $url, "method": $method, "username": $username, "password": $password, "skipFramesWithNoFaces": $skip_frames_with_no_faces, "retentionTime": $retention_time, "storeOriginalFrames": $store_original_frames, "storeAttendanceFaces": $store_attendance_faces, "storeAttendanceFrames": $store_attendance_frames, "isActive": $is_active, "associatedCollections": $associated_collections, "attributes": $attributes} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200 204]
}
