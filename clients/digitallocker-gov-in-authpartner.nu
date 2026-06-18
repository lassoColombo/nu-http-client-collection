# Auto-generated client for Authorized Partner API Specification v1.0.0
# Source: https://api.apis.guru/v2/specs/digitallocker.gov.in/authpartner/1.0.0/openapi.json
# Auth: --token flag or $env.AUTHORIZED_PARTNER_API_SPECIFICATION_TOKEN

const BASE_URL = "https://betaapi.digitallocker.gov.in/public"
const DEFAULT_AUTH = "x-2"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AUTHORIZED_PARTNER_API_SPECIFICATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-2" => { {headers: {X-2: $token_val}, query: ""} }
    "x1123" => { {headers: {X1123: $token_val}, query: ""} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
def build-multipart-body [parts: record, file_fields: list<string>]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | transpose k v | where {|p| $p.v != null} | each {|p|
    let name = $p.k
    let val = $p.v
    if $name in $file_fields {
      let filename = ($val | path basename)
      let bytes = (open --raw $val | into binary | collect)
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  })
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://betaapi.digitallocker.gov.in/public"] }
def auth-scheme-completer [] { ["x-2" "x1123" "bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/pdf" "image/jpeg" "image/jpg" "image/png"] }
def token-type-hint-completer [] { ["access_token" "refresh_token"] }
def gender-completer [] { ["F" "M" "T"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-1-pushuri push-uri" } } | get name | first)
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

# Push URI to Account
#
# POST /account/1/pushuri
# operationId: Push URI to Account id
export def "account-1-pushuri push-uri" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # Action that needs to be taken for the Aadhaar number and URI combination. Possible values are A for adding a new URI, U for updating an already added URI details or D for deleting the URI.
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --digilockerid: int # This is the DigiLocker Id of the user that was acquired using Get User Details API.
  --docid: string # A unique number of the document. This id will be unique within the document type issued by the issuer.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --issuedate: string # The issue date of the document in DDMMYYYY format.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
  --uri: string # This is the unique identifier of the document.
  --validfrom: int # The date from which the document is valid in DDMMYYYY format. This may be same as the issue date.
  --validto: string # The expiry date of the document in DDMMYYYY format.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/1/pushuri")
  let req_body = {"action": $action, "clientid": $clientid, "digilockerid": $digilockerid, "docid": $docid, "hmac": $hmac, "issuedate": $issuedate, "ts": $ts, "uri": $uri, "validfrom": $validfrom, "validto": $validto} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["hmac"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Verify Account
#
# POST /account/2/verify
# operationId: Verify Account id
export def "account-2-verify verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --mobile: int # This is the mobile number of the user. DigiLocker will check whether an account exists for this mobile number. Either uid or mobile is required to verify whether an account exists.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
  --uid: int # This is the Aadhaar number of the user. DigiLocker will check whether an account exists for this Aadhaar number. Either uid or mobile is required to verify whether an account exists.
]: any -> record<digilockerid: string, registered: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/2/verify")
  let req_body = {"clientid": $clientid, "hmac": $hmac, "mobile": $mobile, "ts": $ts, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["hmac"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get Authorization Code
#
# GET /oauth2/1/authorize
# operationId: Get Authorization Code id
export def "oauth2-1-authorize get-authorization-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Provide the client id that was created during the application registration process on Partners Portal.
  --response-type: string # Provide the grant type requested, either token or code.
  --redirect-uri: string # The URI to redirect the user after authorization has completed.
  --state: string # This is your application specific data that will be passed back to your application through redirect_uri.
  --code-challenge: string # A unique random string called code verifier (code_verifier) is created by the client application for every authorization request. The code_challenge sent as this parameter is the Base64URL (with no padding) encoded SHA256 hash of the code verifier. Code block: ``` string base64_url_encode_without_padding(string arg) { string s = base64encode(arg); //Regular base64encoder with padding s = s.replace(’=’,’’); //Remove any trailing ’=’ s = s.replace(’+’, ’-’); //Replace ’+’ with ’-’ s = s.replace(’/’, ’_’); //Replace ’/’ with ’_’ return s; } ``` (e.g. base64_url_encode_without_padding(sha256(code_verifier)))
  --code-challenge-method: string # Specifies what method was used to encode a code_verifier to generate code_challenge parameter above. This parameter must be used with the code_challenge parameter. The only supported values for this parameter is S256.
  --dl-flow: string # If this parameter is provided its value will always be signup. This parameter indicates that the user does not have a DigiLocker account and will be directed to the signup flow directly. After the account is created, the user will be directed to the authorization flow. If this parameter is not sent, the user will be redirected to the sign in flow.
  --verified-mobile: int # Verified mobile number of the user. If this parameter is passed, DigiLocker will skip the mobile OTP verification step during sign up. DigiLocker will treat the mobile number passed in this parameter as a verified mobile number by the trusted client application. This parameter will be used only if dl_flow parameter mentioned above is set to signup and will be ignored otherwise.
]: nothing -> record<details: record<access_token: string, expires_in: int, scope: string, token_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "response_type" $response_type "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "Code_challenge" $code_challenge "scalar") (serialize-qp "Code_challenge_method" $code_challenge_method "scalar") (serialize-qp "dl_flow" $dl_flow "scalar") (serialize-qp "Verified_mobile" $verified_mobile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth2/1/authorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Device Code
#
# POST /oauth2/1/code
# operationId: Get Device Code id
export def "oauth2-1-code get-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --dl-mobile: int # Mobile number associated with DigiLocker account of the user. The client device accepts the mobile number on the device from user and sends it in this parameter. Either the username or the mobile number must be provided.
  --dl-username: string # DigiLocker username of the user. The client device accepts the username on the device from user and sends the username in this parameter. Either the username or the mobile number must be provided.
  --response-type: string # The parameter must be set to device_code. (e.g. device_code)
]: any -> record<device_code: string, dl_masked_email: string, dl_masked_mobile: int, expires_in: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/code")
  let req_body = {"client_id": $client_id, "dl_mobile": $dl_mobile, "dl_username": $dl_username, "response_type": $response_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Upload file to locker
#
# POST /oauth2/1/file/upload
# operationId: Upload File to Locker id
export def "oauth2-1-file-upload upload-to-locker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The destination path of the file in DigiLocker including filename.
  --hmac: string # This is used to verify the integrity of the file data. The client app calculates the hash message authentication code (HMAC) of the file content using SHA256 hashing algorithm and the client secret as the hashing key. The resulting HMAC is converted to Base64 format and sent in this parameter. Upon upload of file, DigiLocker calculates the HMAC of the file data and compares it with this HMAC..
  --body: record
]: any -> record<details: record<Path: string, size: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/file/upload")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"path": $path, "hmac": $hmac} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $req_body
}

# Get File from URI
#
# GET /oauth2/1/file/{uri}
# operationId: Get File from URI id
export def "oauth2-1-file get" [
  uri: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({uri: (encode-path-segment $uri)} | format pattern "/oauth2/1/file/{uri}"))
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List of Self Uploaded Documents
#
# GET /oauth2/1/files/
# operationId: Get List of Self Uploaded Documents
export def "oauth2-1-files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<directory: string, items: table<date: string, description: string, id: string, issuer: string, mime: string, name: string, parent: string, size: string, type: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/files/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Issued Documents
#
# GET /oauth2/1/files/issued
# operationId: Get List of issued Documents Version1 id
export def "oauth2-1-files-issued get-list-of-documents-version1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<details: record<date: string, description: string, doctype: string, issuer: string, issuerid: string, mime: string, name: string, parent: string, size: string, type: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/files/issued")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List of Self Uploaded Documents
#
# GET /oauth2/1/files/{id}
# operationId: Get List of Self Uploaded Documents id
export def "oauth2-1-files get-list-of-self-uploaded-documents" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<details: record<date: string, description: string, id: int, issuer: string, mime: string, name: string, parent: string, size: string, type: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/oauth2/1/files/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List of Documents Provided by an Issuer
#
# POST /oauth2/1/pull/doctype
# operationId: Get List of Documents Provided by an Issuer id
export def "oauth2-1-pull-doctype get-list-of-documents-provided-by-issuer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --orgid: string # The organization id for the issuer in DigiLocker. This organization id is returned in Get List of Issuers API mentioned earlier.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> record<documents: table<description: string, doctype: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/pull/doctype")
  let req_body = {"clientid": $clientid, "hmac": $hmac, "orgid": $orgid, "ts": $ts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Get List of Issuers
#
# POST /oauth2/1/pull/issuers
# operationId: Get List of Issuers id
export def "oauth2-1-pull-issuers get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> record<issuers: table<categories: string, description: string, issuerid: string, name: string, orgid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/pull/issuers")
  let req_body = {"clientid": $clientid, "hmac": $hmac, "ts": $ts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Get Search Parameters for a Document
#
# POST /oauth2/1/pull/parameters
# operationId: Get Search Parameters for a Document id
export def "oauth2-1-pull-parameters get-list-for-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --doctype: string # A 5 character unique document type provided by DigiLocker.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --orgid: string # The organization id for the issuer in DigiLocker. This organization id is returned in Get List of Issuers API mentioned earlier.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> table<example: string, label: string, paramname: string, valuelist: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/pull/parameters")
  let req_body = {"clientid": $clientid, "doctype": $doctype, "hmac": $hmac, "orgid": $orgid, "ts": $ts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Pull Document
#
# POST /oauth2/1/pull/pulldocument
# operationId: Pull Document id
export def "oauth2-1-pull-pulldocument pull-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chasis-no: string # Other parameters required for fetching a document as listed in paramname field of Get Search Parameters API.
  --consent: string # The consent indicator from the user for performing demographic authentication using Aadhaar details. This Partner Application must capture the user consent for performing the Aadhaar demographic authentication. The possible values are ‘Y’ and ‘N’. The sign up request will be processed only when this indicator is ‘Y’.
  --doctype: string # A 5 character unique document type provided by DigiLocker.
  --orgid: string # The organization id for the issuer in DigiLocker. This organization id is returned in Get List of Issuers API mentioned above.
  --reg-no: string # Other parameters required for fetching a document as listed in paramname field of Get Search Parameters API.
]: any -> record<details: record<uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/pull/pulldocument")
  let req_body = {"chasis_no": $chasis_no, "consent": $consent, "doctype": $doctype, "orgid": $orgid, "reg_no": $reg_no} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Revoke Token.
#
# POST /oauth2/1/revoke
# operationId: get token revocation id
export def "oauth2-1-revoke get-token-revocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The token that needs to be revoked.
  --token-type-hint: string@token-type-hint-completer # The type of the above token. The value will be one of access_token or refresh_token. If this parameter is not sent, DigiLocker will look for this token in both access and refresh tokens and then revoke it.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/revoke")
  let req_body = {"token": $body_token, "token_type_hint": $token_type_hint} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Access Token
#
# POST /oauth2/1/token
# operationId: getaccesstoken id
# --Get access token using authorization code shape: {client_id: string, client_secret: string, code?: string, code_verifier?: string, grant_type: "authorization_code", redirect_uri?: string}
# --Get access token using device code and OTP shape: {client_id?: string, device_code?: string, dl_otp?: string, grant_type?: string}
# --Get access token using refresh token shape: {client_id: string, client_secret: string, grant_type: "refresh_token", refresh_token: string}
export def "oauth2-1-token create-getaccesstoken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --get-access-token-using-authorization-code: record # shape: {client_id: string, client_secret: string, code?: string, code_verifier?: string, grant_type: "authorization_code", redirect_uri?: string}
  --get-access-token-using-device-code-and-otp: any # shape: {client_id?: string, device_code?: string, dl_otp?: string, grant_type?: string}
  --get-access-token-using-refresh-token: record # shape: {client_id: string, client_secret: string, grant_type: "refresh_token", refresh_token: string}
]: any -> record<access_token: string, digilocker_id: string, dob: int, eaadhar: string, expires_in: int, gender: string, name: string, reference_key: string, refresh_token: string, scope: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-2"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/token")
  let req_body = {"Get access token using authorization code": $get_access_token_using_authorization_code, "Get access token using device code and OTP": $get_access_token_using_device_code_and_otp, "Get access token using refresh token": $get_access_token_using_refresh_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get User Details
#
# GET /oauth2/1/user
# operationId: Account Detail API id
export def "oauth2-1-user get-account-detail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<details: record<digilockerid: string, dob: string, eaadhar: string, gender: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/1/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Certificate Data in XML Format from URI
#
# GET /oauth2/1/xml/{uri}
# operationId: Get Certificate Data in XML Format from URI id
export def "oauth2-1-xml get-certificate-data-in-format" [
  uri: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({uri: (encode-path-segment $uri)} | format pattern "/oauth2/1/xml/{uri}"))
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Issued Documents
#
# GET /oauth2/2/files/issued
# operationId: Get List of issued Documents id
export def "oauth2-2-files-issued get-list-of-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<date: string, description: string, doctype: string, issuer: string, issuerid: string, mime: list, name: string, parent: string, size: string, type: string, uri: string>, resource: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-2"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/2/files/issued")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get e-Aadhaar Data in XML Format
#
# GET /oauth2/2/xml/eaadhaar
# operationId: Get e-Aadhaar Data in XML Format id
export def "oauth2-2-xml-eaadhaar get-e-aadhaar-data-in-format" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/2/xml/eaadhaar")
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify OTP
#
# POST /signup/1/demoauthverify
# operationId: Verify OTP id
export def "signup-1-demoauthverify verify-otp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --mobile: int # This is the mobile number of the user. DigiLocker will check whether an account exists for this mobile number. Either uid or mobile is required to verify whether an account exists.
  --otp: int # The OTP provided by the user.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> record<details: record<access_token: string, expires_in: string, refresh_token: string, scope: string, token_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signup/1/demoauthverify")
  let req_body = {"clientid": $clientid, "hmac": $hmac, "mobile": $mobile, "otp": $otp, "ts": $ts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["hmac"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# SIGN UP
#
# POST /signup/2/demoauth
# operationId: SIGN UP id
export def "signup-2-demoauth create-sign-up" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --consent: string # The consent indicator from the user for performing demographic authentication using Aadhaar details. This Partner Application must capture the user consent for performing the Aadhaar demographic authentication. The possible values are ‘Y’ and ‘N’. The sign up request will be processed only when this indicator is ‘Y’.
  --demoauth: string # The parameter indicates whether Aadhaar demographic authentication must be successful for creating DigiLocker account. The possible values are ‘Y’ and ‘N’. The value of ‘Y’ will perform Aadhaar demographic authentication and will return errors if any in response. The value of ‘N’ will also perform Aadhaar demographic authentication but will return any error in case of authentication failure. It will create a basic mobile based account for the user. Value ‘N’ should be used when the user account needs to be created in the absence of the user.
  --dob: int # This is date of birth of the user as mentioned in Aadhaar in DDMMYYYY format.
  --gender: any@gender-completer # This is gender of the user as mentioned in Aadhaar. The possible values are M, F, T for male, female and transgender respectively.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --mobile: int # This is the mobile number of the user. DigiLocker will check whether an account exists for this mobile number. Either uid or mobile is required to verify whether an account exists.
  --name: string # This is name of the user as mentioned in Aadhaar.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
  --uid: int # This is the Aadhaar number of the user. DigiLocker will check whether an account exists for this Aadhaar number. Either uid or mobile is required to verify whether an account exists.
  --verification: string # The parameter indicates whether the mobile number provided above should be validated by DigiLocker. If this parameter is ‘Y’, the DigiLocker sends an OTP to verify the mobile number. In this case the client application will call the second API to validate the OTP. The user will be signed on only after successful OTP validation. This flow should be used when the user account is created by user himself/herself or the user is present to provide the OTP. If this parameter is ‘N’, the user account will be created without OTP validation. The OTP validation will be performed when the user signs in for the first time in DigiLocker. This flow should be used when the user account needs to be created in the absence of the user.
]: any -> record<details: record<access_token: string, expires_in: string, mobile: int, refresh_token: string, scope: string, token_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signup/2/demoauth")
  let req_body = {"clientid": $clientid, "consent": $consent, "demoauth": $demoauth, "dob": $dob, "gender": $gender, "hmac": $hmac, "mobile": $mobile, "name": $name, "ts": $ts, "uid": $uid, "verification": $verification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["hmac"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get Statistics
#
# POST /statistics/1/counts
# operationId: Get Statistics id
export def "statistics-1-counts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> record<authentic_documents: string, count_as_on: string, issuers: string, monthwise_registations: record<count: int, details2: record<count: int, id: int, month: int, year: int>, id: int, month: int, year: int>, requestors: string, users: string, yearwise_authentic_documents: record<count: int, details: record<count: int, id: int, year: int>, details1: record<count: int, id: int, year: int>, details2: record<count: int, id: int, year: int>, id: int, year: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/statistics/1/counts")
  let req_body = {"clientid": $clientid, "hmac": $hmac, "ts": $ts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["hmac"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}
