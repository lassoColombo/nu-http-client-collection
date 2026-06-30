# Auto-generated client for Account and Transaction API Specification - UK vv3.1.5
# Source: https://api.apis.guru/v2/specs/nbg.gr/v3.1.5/openapi.json
# Auth: --token flag or $env.ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_TOKEN

const BASE_URL = "https://apis.nbg.gr/sandbox/uk.openbanking.accountinfo/oauth2/v3.1.5"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "client-id" => { {scheme: $scheme, headers: {Client-Id: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://apis.nbg.gr/sandbox/uk.openbanking.accountinfo/oauth2/v3.1.5" "https://services.nbg.gr/apis/open-banking/v3.1.5/aisp"] }
def auth-scheme-completer [] { ["bearer" "client-id"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/json; charset=utf-8"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-access-consents create" } } | get name | first)
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

# Create Account Access Consents
#
# POST /account-access-consents
# --Data shape: {ExpirationDateTime?: string, Permissions: list<string>, TransactionFromDateTime?: string, TransactionToDateTime?: string}
export def "account-access-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-clientcredentialstoken: string # Auth token for Client-Credentials-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
  data: record # shape: {ExpirationDateTime?: string, Permissions: list<string>, TransactionFromDateTime?: string, TransactionToDateTime?: string}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Account Info.
]: any -> record<Data: record<ConsentId: string, CreationDateTime: string, ExpirationDateTime: string, Permissions: list<string>, Status: string, StatusUpdateDateTime: string, TransactionFromDateTime: string, TransactionToDateTime: string>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>, Risk: record> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_clientcredentialstoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTCREDENTIALSTOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account-access-consents" $auth.query)
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete Account Access Consents
#
# DELETE /account-access-consents/{consentId}
export def "account-access-consents delete" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-clientcredentialstoken: string # Auth token for Client-Credentials-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_clientcredentialstoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTCREDENTIALSTOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'consentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/account-access-consents/{consent_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get Account Access Consents
#
# GET /account-access-consents/{consentId}
export def "account-access-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-clientcredentialstoken: string # Auth token for Client-Credentials-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<ConsentId: string, CreationDateTime: string, ExpirationDateTime: string, Permissions: list<string>, Status: string, StatusUpdateDateTime: string, TransactionFromDateTime: string, TransactionToDateTime: string>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>, Risk: record> {
  let auth = (merge-auth [(build-auth ($token_clientcredentialstoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTCREDENTIALSTOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'consentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/account-access-consents/{consent_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Accounts
#
# GET /accounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Account: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Accounts
#
# GET /accounts/{accountId}
export def "accounts get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Account: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Balances
#
# GET /accounts/{accountId}/balances
export def "accounts-balances get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Balance: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/balances") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Beneficiaries
#
# GET /accounts/{accountId}/beneficiaries
export def "accounts-beneficiaries get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Beneficiary: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/beneficiaries") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Parties
#
# GET /accounts/{accountId}/parties
export def "accounts-parties get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Party: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/parties") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Party
#
# GET /accounts/{accountId}/party
export def "accounts-party get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Party: record<Name: string, PartyId: string>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/party") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Scheduled Payments
#
# GET /accounts/{accountId}/scheduled-payments
export def "accounts-scheduled-payments get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<ScheduledPayment: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/scheduled-payments") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Standing Orders
#
# GET /accounts/{accountId}/standing-orders
export def "accounts-standing-orders get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<StandingOrder: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/standing-orders") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Statements
#
# GET /accounts/{accountId}/statements
export def "accounts-statements list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from-statement-date-time: string # The UTC ISO 8601 Date Time to filter statements FROM NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (nullable, format: date-time)
  --to-statement-date-time: string # The UTC ISO 8601 Date Time to filter statements TO NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (nullable, format: date-time)
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Statement: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "fromStatementDateTime" $from_statement_date_time "scalar") (serialize-qp "toStatementDateTime" $to_statement_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/statements") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fromStatementDateTime": $from_statement_date_time, "toStatementDateTime": $to_statement_date_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Statements
#
# GET /accounts/{accountId}/statements/{statementId}
export def "accounts-statements get" [
  account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Statement: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'statementId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), statement_id: (encode-path-segment $statement_id)} | format pattern "/accounts/{account_id}/statements/{statement_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Statements
#
# GET /accounts/{accountId}/statements/{statementId}/file
export def "accounts-statements-file get" [
  account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> oneof<string, record, nothing> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'statementId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), statement_id: (encode-path-segment $statement_id)} | format pattern "/accounts/{account_id}/statements/{statement_id}/file") $auth.query)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Transactions
#
# GET /accounts/{accountId}/statements/{statementId}/transactions
export def "accounts-statements-transactions get" [
  account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Transaction: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'statementId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), statement_id: (encode-path-segment $statement_id)} | format pattern "/accounts/{account_id}/statements/{statement_id}/transactions") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Get Transactions
#
# GET /accounts/{accountId}/transactions
export def "accounts-transactions get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from-booking-date-time: string # The UTC ISO 8601 Date Time to filter transactions FROM NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (nullable, format: date-time)
  --to-booking-date-time: string # The UTC ISO 8601 Date Time to filter transactions TO NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (nullable, format: date-time)
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Transaction: list<record>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "fromBookingDateTime" $from_booking_date_time "scalar") (serialize-qp "toBookingDateTime" $to_booking_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/transactions") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fromBookingDateTime": $from_booking_date_time, "toBookingDateTime": $to_booking_date_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Party
#
# GET /party
export def "party get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  --sandbox-id: string # The unique id of the sandbox to be used
]: nothing -> record<Data: record<Party: record<Name: string, PartyId: string>>, Links: record<First: string, Last: string, Next: string, Prev: string, Self: string>, Meta: record<FirstAvailableDateTime: string, LastAvailableDateTime: string, TotalPages: int>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/party" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "x-customer-user-agent": $x_customer_user_agent, "sandbox-id": $sandbox_id} | compact
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

# Create Sandbox
#
# POST /sandbox
export def "sandbox create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  sandbox_id: string # Sandbox Id
]: any -> record<sandboxId: string, users: table<accounts: list, cards: list, retryCacheEntries: list, userId: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox" $auth.query)
  let req_body = {"sandboxId": $sandbox_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Import Sandbox
#
# PUT /sandbox
# --users item shape: {accounts?: list, cards?: list, retryCacheEntries?: list, userId?: string}
export def "sandbox update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  sandbox_id: string # Sandbox id
  --users: list # List of users (nullable) — item shape: {accounts?: list, cards?: list, retryCacheEntries?: list, userId?: string}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox" $auth.query)
  let req_body = {"sandboxId": $sandbox_id, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete Sandbox
#
# DELETE /sandbox/{sandboxId}
export def "sandbox delete" [
  sandbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($sandbox_id | is-empty) { error make --unspanned { msg: "path parameter 'sandboxId' must be non-empty" } }
  let full_url = (build-url $base ({sandbox_id: (encode-path-segment $sandbox_id)} | format pattern "/sandbox/{sandbox_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Export Sandbox
#
# GET /sandbox/{sandboxId}
export def "sandbox get" [
  sandbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-authorizationcodetoken: string # Auth token for Authorization-Code-Token (Authorization)
  --token-clientid: string # Auth token for Client-Id (Client-Id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<sandboxId: string, users: table<accounts: list, cards: list, retryCacheEntries: list, userId: string>> {
  let auth = (merge-auth [(build-auth ($token_authorizationcodetoken | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_AUTHORIZATIONCODETOKEN_TOKEN | default "")) "bearer") (build-auth ($token_clientid | default ($env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_UK_CLIENTID_TOKEN | default "")) "client-id")])
  let base = ($base_url | default $BASE_URL)
  if ($sandbox_id | is-empty) { error make --unspanned { msg: "path parameter 'sandboxId' must be non-empty" } }
  let full_url = (build-url $base ({sandbox_id: (encode-path-segment $sandbox_id)} | format pattern "/sandbox/{sandbox_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
