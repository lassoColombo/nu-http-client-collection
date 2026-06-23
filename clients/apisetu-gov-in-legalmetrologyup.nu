# Auto-generated client for Department of Legal Metrology, Uttar Pradesh v3.0.0
# Source: https://api.apis.guru/v2/specs/apisetu.gov.in/legalmetrologyup/3.0.0/openapi.json
# Auth: --token flag or $env.DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_TOKEN

const BASE_URL = "https://apisetu.gov.in/legalmetrologyup/v3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-apisetu-apikey" => { {scheme: $scheme, headers: {X-APISETU-APIKEY: $token_val}, query: "", location: "header"} }
    "x-apisetu-clientid" => { {scheme: $scheme, headers: {X-APISETU-CLIENTID: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

def base-url-completer [] { ["https://apisetu.gov.in/legalmetrologyup/v3"] }
def auth-scheme-completer [] { ["x-apisetu-apikey" "x-apisetu-clientid"] }

# Completers for enum parameters
def format-completer [] { ["pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "delcs-certificate create" } } | get name | first)
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

# Dealer License
#
# POST /delcs/certificate
# operationId: delcs
# --certificateParameters shape: {applicationNo: string, licenseNo: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "delcs-certificate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for apiKey (X-APISETU-APIKEY)
  --token-clientid: string # Auth token for clientId (X-APISETU-CLIENTID)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate-parameters: record # shape: {applicationNo: string, licenseNo: string}
  --consent-artifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txn_id: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_apikey | default ($env | get -o DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_APIKEY_TOKEN | default "")) "x-apisetu-apikey") (build-auth ($token_clientid | default ($env | get -o DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_CLIENTID_TOKEN | default "")) "x-apisetu-clientid")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/delcs/certificate")
  let req_body = {"certificateParameters": $certificate_parameters, "consentArtifact": $consent_artifact, "format": $format, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Manufacturer License
#
# POST /malcs/certificate
# operationId: malcs
# --certificateParameters shape: {applicationNo: string, licenseNo: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "malcs-certificate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for apiKey (X-APISETU-APIKEY)
  --token-clientid: string # Auth token for clientId (X-APISETU-CLIENTID)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate-parameters: record # shape: {applicationNo: string, licenseNo: string}
  --consent-artifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txn_id: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_apikey | default ($env | get -o DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_APIKEY_TOKEN | default "")) "x-apisetu-apikey") (build-auth ($token_clientid | default ($env | get -o DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_CLIENTID_TOKEN | default "")) "x-apisetu-clientid")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/malcs/certificate")
  let req_body = {"certificateParameters": $certificate_parameters, "consentArtifact": $consent_artifact, "format": $format, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Packers License
#
# POST /palcs/certificate
# operationId: palcs
# --certificateParameters shape: {applicationNo: string, licenseNo: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "palcs-certificate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for apiKey (X-APISETU-APIKEY)
  --token-clientid: string # Auth token for clientId (X-APISETU-CLIENTID)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate-parameters: record # shape: {applicationNo: string, licenseNo: string}
  --consent-artifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txn_id: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_apikey | default ($env | get -o DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_APIKEY_TOKEN | default "")) "x-apisetu-apikey") (build-auth ($token_clientid | default ($env | get -o DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_CLIENTID_TOKEN | default "")) "x-apisetu-clientid")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/palcs/certificate")
  let req_body = {"certificateParameters": $certificate_parameters, "consentArtifact": $consent_artifact, "format": $format, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Repairer License
#
# POST /relcs/certificate
# operationId: relcs
# --certificateParameters shape: {applicationNo: string, licenseNo: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "relcs-certificate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for apiKey (X-APISETU-APIKEY)
  --token-clientid: string # Auth token for clientId (X-APISETU-CLIENTID)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate-parameters: record # shape: {applicationNo: string, licenseNo: string}
  --consent-artifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txn_id: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_apikey | default ($env | get -o DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_APIKEY_TOKEN | default "")) "x-apisetu-apikey") (build-auth ($token_clientid | default ($env | get -o DEPARTMENT_OF_LEGAL_METROLOGY_UTTAR_PRADESH_CLIENTID_TOKEN | default "")) "x-apisetu-clientid")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/relcs/certificate")
  let req_body = {"certificateParameters": $certificate_parameters, "consentArtifact": $consent_artifact, "format": $format, "txnId": $txn_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
