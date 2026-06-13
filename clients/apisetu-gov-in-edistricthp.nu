# Auto-generated client for eDistrict Himachal Pradesh, Himachal Pradesh v3.0.0
# Source: https://api.apis.guru/v2/specs/apisetu.gov.in/edistricthp/3.0.0/openapi.json
# Auth: --token flag or $env.EDISTRICT_HIMACHAL_PRADESH_HIMACHAL_PRADESH_TOKEN

const BASE_URL = "https://apisetu.gov.in/edistricthp/v3"
const DEFAULT_AUTH = "x-apisetu-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EDISTRICT_HIMACHAL_PRADESH_HIMACHAL_PRADESH_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-apisetu-apikey" => { {headers: {X-APISETU-APIKEY: $token_val}, query: ""} }
    "x-apisetu-clientid" => { {headers: {X-APISETU-CLIENTID: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://apisetu.gov.in/edistricthp/v3"] }
def auth-scheme-completer [] { ["x-apisetu-apikey" "x-apisetu-clientid"] }

# Completers for enum parameters
def format-completer [] { ["pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "aecmw-certificate aecmw" } } | get name | first)
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

# Application for Renewal of Contractor Migrant Workmen license
#
# POST /aecmw/certificate
# operationId: aecmw
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "aecmw-certificate aecmw" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aecmw/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Application for Renewal of Motor Transport Worker Registration
#
# POST /aemtw/certificate
# operationId: aemtw
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "aemtw-certificate aemtw" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aemtw/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Agriculture/ Agriculturist Certificate
#
# POST /agcer/certificate
# operationId: agcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "agcer-certificate agcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/agcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Application for License for Inter State Migrant Workmen
#
# POST /alimw/certificate
# operationId: alimw
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "alimw-certificate alimw" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alimw/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Application for Registration of Contractor Migrant Workmen license
#
# POST /arcmw/certificate
# operationId: arcmw
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "arcmw-certificate arcmw" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/arcmw/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Application for Registration of Motor Transport Worker Registration
#
# POST /armtw/certificate
# operationId: armtw
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "armtw-certificate armtw" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/armtw/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Backward Area Certificate
#
# POST /bacer/certificate
# operationId: bacer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "bacer-certificate bacer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bacer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bonafide Certificate
#
# POST /bhcer/certificate
# operationId: bhcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "bhcer-certificate bhcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bhcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# BPL Card
#
# POST /bpcrd/certificate
# operationId: bpcrd
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "bpcrd-certificate bpcrd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bpcrd/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Birth Certificate
#
# POST /btcer/certificate
# operationId: btcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "btcer-certificate btcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/btcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Renewal Certificate of Contract Labour License
#
# POST /cecer/certificate
# operationId: cecer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "cecer-certificate cecer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cecer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Character Certificate
#
# POST /chcer/certificate
# operationId: chcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "chcer-certificate chcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Registration Certificate for Contract Labour License
#
# POST /clcer/certificate
# operationId: clcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "clcer-certificate clcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copy of Pariwar Register
#
# POST /coprg/certificate
# operationId: coprg
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "coprg-certificate coprg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coprg/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Dogra Class Certificate
#
# POST /dccer/certificate
# operationId: dccer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "dccer-certificate dccer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dccer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Domicile Certificate
#
# POST /dmcer/certificate
# operationId: dmcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "dmcer-certificate dmcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dmcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disabled Person Identity Card/ Certificate
#
# POST /dpicr/certificate
# operationId: dpicr
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "dpicr-certificate dpicr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dpicr/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Death Certificate
#
# POST /dtcer/certificate
# operationId: dtcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "dtcer-certificate dtcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dtcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Registration Certificate of Establishment Employing Contract Labour
#
# POST /ercer/certificate
# operationId: ercer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "ercer-certificate ercer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ercer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Freedom Fighter Certificate
#
# POST /ffcer/certificate
# operationId: ffcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "ffcer-certificate ffcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ffcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Indigent (Needy Person) Certificate
#
# POST /igcer/certificate
# operationId: igcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "igcer-certificate igcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/igcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Income Certificate
#
# POST /incer/certificate
# operationId: incer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "incer-certificate incer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Legal Heir Certificate
#
# POST /lhcer/certificate
# operationId: lhcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "lhcer-certificate lhcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lhcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Minority Certificate
#
# POST /mncer/certificate
# operationId: mncer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "mncer-certificate mncer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mncer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# MNREGA Job Card
#
# POST /mnrga/certificate
# operationId: mnrga
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "mnrga-certificate mnrga" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mnrga/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OBC Certificate
#
# POST /obcer/certificate
# operationId: obcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "obcer-certificate obcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/obcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rural Area Certificate
#
# POST /racer/certificate
# operationId: racer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "racer-certificate racer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/racer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Marriage Certificate
#
# POST /rmcer/certificate
# operationId: rmcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "rmcer-certificate rmcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rmcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Renewal Certificate of Shops And Commercial Establishment
#
# POST /secer/certificate
# operationId: secer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "secer-certificate secer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SC/ST  Certificate
#
# POST /shcer/certificate
# operationId: shcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "shcer-certificate shcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Senior Citizen Identity Card/ Certificate
#
# POST /sicrd/certificate
# operationId: sicrd
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "sicrd-certificate sicrd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sicrd/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Registration Certificate of Shops And Commercial Establishment
#
# POST /srcer/certificate
# operationId: srcer
# --certificateParameters shape: {UDF1: string}
# --consentArtifact shape: {consent: record, signature: record}
export def "srcer-certificate srcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificateParameters: record # shape: {UDF1: string}
  --consentArtifact: any # shape: {consent: record, signature: record}
  format: string@format-completer # The format of the certificate in response.
  txnId: string # A unique transaction id for this request in UUID format. It is used for tracking the request. (format: uuid, e.g. f7f1469c-29b0-4325-9dfc-c567200a70f7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apisetu-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/srcer/certificate")
  let body = {certificateParameters: $certificateParameters, consentArtifact: $consentArtifact, format: $format, txnId: $txnId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
