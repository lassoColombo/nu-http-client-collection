# Auto-generated client for Customer Credit API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Customer-Credit-API/1.0/openapi.json
# Auth: --token flag or $env.CUSTOMER_CREDIT_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CUSTOMER_CREDIT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "creditcontrol-accounts get-searchallaccounts" } } | get name | first)
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

# Search all accounts
#
# GET /api/creditcontrol/accounts
# operationId: Searchallaccounts
export def "creditcontrol-accounts get-searchallaccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> record<data: table<account: string, balance: float, creditLimit: float, description: string, document: string, documentType: string, email: string, lastUpdate: string>, summary: record<count: int>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/creditcontrol/accounts" $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Open an Account
#
# POST /api/creditcontrol/accounts
# operationId: OpenanAccount
export def "creditcontrol-accounts create-openan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  credit_limit: string # default: 500
  description: string # default: example
  document: string # default: 99999999999
  document_type: string # default: CPF
  email: string # default: email@domain.com
  tolerance: string # default: 1
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/creditcontrol/accounts" $auth.query)
  let req_body = {"creditLimit": $credit_limit, "description": $description, "document": $document, "documentType": $document_type, "email": $email, "tolerance": $tolerance} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Open or Change Account
#
# PUT /api/creditcontrol/accounts/{accountId}
# operationId: OpenorChangeAccount
export def "creditcontrol-accounts update-openor-change" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --credit-limit: int # If the user don't set a credit limit, the system will define 100 for default (default: 100.0)
  --document: string # default: 00221292404
  email: string # default: email@email.com
  id: string # default: teste
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/api/creditcontrol/accounts/{account_id}") $auth.query)
  let req_body = {"creditLimit": $credit_limit, "document": $document, "email": $email, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Close an Account
#
# DELETE /api/creditcontrol/accounts/{creditAccountId}
# operationId: CloseanAccount
export def "creditcontrol-accounts delete-closean" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --document: string # default: 99999999999
  --document-type: string # default: CPF
  --email: string # default: email@domain.com
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}") $auth.query)
  let req_body = {"document": $document, "documentType": $document_type, "email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve an Account by Id
#
# GET /api/creditcontrol/accounts/{creditAccountId}
# operationId: RetrieveaAccountbyId
export def "creditcontrol-accounts get-retrievea-accountby" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> record<account: string, balance: float, creditLimit: float, description: string, email: string, lastUpdate: string> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Update email and description of a account
#
# PUT /api/creditcontrol/accounts/{creditAccountId}
# operationId: Updateemailanddescriptionofaaccount
export def "creditcontrol-accounts update-emailanddescriptionofaaccount" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  description: string # default: example
  email: string # default: email@domain.com
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}") $auth.query)
  let req_body = {"description": $description, "email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Change credit limit of an Account
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/creditlimit
# operationId: ChangecreditlimitofanAccount
export def "creditcontrol-accounts-creditlimit update-changecreditlimitofan" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  value: int # format: number, default: 500.0
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/creditlimit") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Add an account Holder
#
# POST /api/creditcontrol/accounts/{creditAccountId}/holders
# operationId: AddanaccountHolder
# --claims shape: {email: string}
export def "creditcontrol-accounts-holders create-addanaccount" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  claims: record # e.g. {email: USER-EMAIL} — shape: {email: string}
]: any -> record<data: table<account: string, balance: float, creditLimit: float, description: string, document: string, documentType: string, email: string, lastUpdate: string>, summary: record<count: int>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/holders") $auth.query)
  let req_body = {"claims": $claims} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete an account holder
#
# DELETE /api/creditcontrol/accounts/{creditAccountId}/holders/{holderId}
# operationId: Deleteanaccountholder
export def "creditcontrol-accounts-holders delete-anaccountholder" [
  credit_account_id: string
  holder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> record<data: table<account: string, balance: float, creditLimit: float, description: string, document: string, documentType: string, email: string, lastUpdate: string>, summary: record<count: int>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($holder_id | is-empty) { error make --unspanned { msg: "path parameter 'holderId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), holder_id: (encode-path-segment $holder_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/holders/{holder_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve invoice by creditAccountId
#
# GET /api/creditcontrol/accounts/{creditAccountId}/invoices
# operationId: SearchallinvoicesofaAccount
export def "creditcontrol-accounts-invoices get-searchallinvoicesofa" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> record<data: table<checkingAccountId: string, createdAt: string, description: string, dueDate: string, id: string, observation: string, originalDueDate: string, paymentLink: string, status: string, updatedAt: string, value: float>, summary: record<count: int, total: float>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/invoices") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Cancel Invoice
#
# DELETE /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}
# operationId: CancelInvoice
export def "creditcontrol-accounts-invoices cancel" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/invoices/{invoice_id}") $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve Invoice by Id
#
# GET /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}
# operationId: RetrieveInvoicebyId
export def "creditcontrol-accounts-invoices get-invoiceby" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> record<checkingAccountId: string, createdAt: string, description: string, dueDate: string, id: string, observation: string, originalDueDate: string, paymentLink: string, status: string, updatedAt: string, value: float> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/invoices/{invoice_id}") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Change Invoice
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}
# operationId: ChangeInvoice
export def "creditcontrol-accounts-invoices update-change" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-id: string # Invoice's identification (default: insert identifier here)
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  observation: string # default: example
  payment_link: string # default: example
  status: string # Invoice's status. It must be completed with "Paid", "Cancelled" or "Open" value. (default: Paid)
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let qp = [(serialize-qp "friendlyId" $friendly_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/invoices/{invoice_id}") $qp $auth.query)
  let req_body = {"observation": $observation, "paymentLink": $payment_link, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: ({"friendlyId": $friendly_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Mark an invoice as Paid
#
# POST /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}/payments
# operationId: MarkaninvoiceasPaid
export def "creditcontrol-accounts-invoices-payments create-markaninvoiceas-paid" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  value: string # default: example
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/invoices/{invoice_id}/payments") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Postpone an invoice
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/invoices/{invoiceId}/postponement
# operationId: Postponeaninvoice
export def "creditcontrol-accounts-invoices-post-ponement create-poneaninvoice" [
  credit_account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  due_days: string
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/invoices/{invoice_id}/postponement") $auth.query)
  let req_body = {"dueDays": $due_days} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Account statements
#
# GET /api/creditcontrol/accounts/{creditAccountId}/statements
# operationId: Accountstatements
export def "creditcontrol-accounts-statements get-accountstatements" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> record<currentBalance: float, intervalBalance: float, previousBalance: float, statements: table<date: string, description: string, value: float>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/statements") $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Decrease balance of an account
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/statements/{statementId}
# operationId: Decreasebalanceofanaccount
export def "creditcontrol-accounts-statements update-decreasebalanceofanaccount" [
  credit_account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  value: string # default: -490.0
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'statementId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), statement_id: (encode-path-segment $statement_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/statements/{statement_id}") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Change tolerance of an account
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/tolerance
# operationId: Changetoleranceofanaccount
export def "creditcontrol-accounts-tolerance update-changetoleranceofanaccount" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  value: float # default: 0.2
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/tolerance") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Create a Pre Authorization
#
# POST /api/creditcontrol/accounts/{creditAccountId}/transaction
# operationId: CreateaPreAuthorization
export def "creditcontrol-accounts-transaction create-createa-pre-authorization" [
  credit_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  expiration_date: string # date in ISO8601 (UTC) dateformat (optional default is 1(one) day) (default: 1)
  installments: string # default: 1
  --settle: oneof<nothing, bool> # default: false
  value: string # default: 490.0
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/transaction") $auth.query)
  let req_body = {"expirationDate": $expiration_date, "installments": $installments, "settle": $settle, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Cancel a Pre Authorization
#
# DELETE /api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}
# operationId: CancelaPreAuthorization
export def "creditcontrol-accounts-transactions delete-cancela-pre-authorization" [
  credit_account_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/transactions/{transaction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Create a Pre Authorization (using id)
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}
# operationId: CreateaPreAuthorization(usingid)
export def "creditcontrol-accounts-transactions update-createa-pre-authorizationusingid" [
  credit_account_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  expiration_date: string # date in ISO8601 (UTC) dateformat (optional default is 1(one) day) (default: 1)
  installments: string # default: 1
  --settle: oneof<nothing, bool> # default: false
  value: string # default: 20.0
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/transactions/{transaction_id}") $auth.query)
  let req_body = {"expirationDate": $expiration_date, "installments": $installments, "settle": $settle, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Partial or Total Refund a Settlement
#
# POST /api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}/refunds
# operationId: PartialorTotalRefundaSettlement
export def "creditcontrol-accounts-transactions-refunds create-partialor-total-refunda-settlement" [
  credit_account_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  value: string # default: 20
]: any -> record<id: string, value: float> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/transactions/{transaction_id}/refunds") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Create or Update Settlement
#
# PUT /api/creditcontrol/accounts/{creditAccountId}/transactions/{transactionId}/settlement
# operationId: CreateorUpdateSettlement
export def "creditcontrol-accounts-transactions-settlement update-createor" [
  credit_account_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  value: string # default: 490.0
]: any -> record<id: string, value: float> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($credit_account_id | is-empty) { error make --unspanned { msg: "path parameter 'creditAccountId' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({credit_account_id: (encode-path-segment $credit_account_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/api/creditcontrol/accounts/{credit_account_id}/transactions/{transaction_id}/settlement") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Search all invoices
#
# GET /api/creditcontrol/invoices
# operationId: Searchallinvoices
export def "creditcontrol-invoices get-searchallinvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # default: 
  --qp-to: string # default: 
  --created-date-from: string # e.g. 
  --created-date-to: string # e.g. 
  --value: float # Invoice's value. It must be completed with a decimal value. (default: 101.22)
  --status: string # Invoice's status. It must be completed with "Paid", "Cancelled" or "Open" value. (default: Paid)
  --friendly-id: string # Invoice's identifier (default: insert identifier here)
  --credit-account-id: string # Credit account's identifier (default: B75F0)
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> record<data: table<checkingAccountId: string, createdAt: string, description: string, dueDate: string, id: string, observation: string, originalDueDate: string, paymentLink: string, status: string, updatedAt: string, value: float>, summary: record<count: int, total: float>> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "createdDateFrom" $created_date_from "scalar") (serialize-qp "createdDateTo" $created_date_to "scalar") (serialize-qp "value" $value "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "friendlyId" $friendly_id "scalar") (serialize-qp "creditAccountId" $credit_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/creditcontrol/invoices" $qp $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $qp_from, "to": $qp_to, "createdDateFrom": $created_date_from, "createdDateTo": $created_date_to, "value": $value, "status": $status, "friendlyId": $friendly_id, "creditAccountId": $credit_account_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve store configuration
#
# GET /api/creditcontrol/storeconfig
# operationId: Retrievestoreconfiguration
export def "creditcontrol-storeconfig get-storeconfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
]: nothing -> record<dailyInterestRate: float, invoicePostponementLimit: int, taxRate: float, tolerancePercent: float> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/creditcontrol/storeconfig" $auth.query)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
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

# Create or change store configuration
#
# PUT /api/creditcontrol/storeconfig
# operationId: Createorchangestoreconfiguration
# --notificationsSettings shape: {daysAfter?: list, daysPrior?: list}
export def "creditcontrol-storeconfig create-orchangestoreconfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Media type(s) that is/are acceptable for the response. Default value for payment provider protocol is application/json
  --content-type: string # The Media type of the body of the request. Default value for payment provider protocol is application/json
  --automatic-checking-account-creation-enabled: oneof<nothing, bool> # default: false
  daily_interest_rate: string # default: 0.6
  default_credit_value: string # default: 150.0
  invoice_postponement_limit: string # default: 2
  max_postponement_days: string # default: 3
  max_pre_authorization_growth_rate: string # default: 0.1
  --my-credits-enabled: oneof<nothing, bool> # default: true
  --notifications-settings: record # shape: {daysAfter?: list, daysPrior?: list}
  --postponement-enabled: oneof<nothing, bool> # default: false
  tax_rate: string # default: 0.4
  --tolerance-enabled: oneof<nothing, bool> # default: true
]: any -> record<dailyInterestRate: float, invoicePostponementLimit: int, taxRate: float, tolerancePercent: float> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CUSTOMER_CREDIT_API_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CUSTOMER_CREDIT_API_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/creditcontrol/storeconfig" $auth.query)
  let req_body = {"automaticCheckingAccountCreationEnabled": $automatic_checking_account_creation_enabled, "dailyInterestRate": $daily_interest_rate, "defaultCreditValue": $default_credit_value, "invoicePostponementLimit": $invoice_postponement_limit, "maxPostponementDays": $max_postponement_days, "maxPreAuthorizationGrowthRate": $max_pre_authorization_growth_rate, "myCreditsEnabled": $my_credits_enabled, "notificationsSettings": $notifications_settings, "postponementEnabled": $postponement_enabled, "taxRate": $tax_rate, "toleranceEnabled": $tolerance_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [200]
}
