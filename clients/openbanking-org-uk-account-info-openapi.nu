# Auto-generated client for Account and Transaction API Specification v3.1.7
# Source: https://api.apis.guru/v2/specs/openbanking.org.uk/account-info-openapi/3.1.7/openapi.json
# Auth: --token flag or $env.ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_TOKEN

const BASE_URL = "https://openbanking.org.uk"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNT_AND_TRANSACTION_API_SPECIFICATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://openbanking.org.uk" "http://localhost/open-banking/v3.1/aisp"] }
def auth-scheme-completer [] { ["bearer"] }


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
# operationId: CreateAccountAccessConsents
# --Data shape: {ExpirationDateTime?: string, Permissions: list<string>, TransactionFromDateTime?: string, TransactionToDateTime?: string}
export def "account-access-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
  data: record # shape: {ExpirationDateTime?: string, Permissions: list<string>, TransactionFromDateTime?: string, TransactionToDateTime?: string}
  risk: record # The Risk section is sent by the initiating party to the ASPSP. It is used to specify additional details for risk scoring for Account Info.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account-access-consents")
  let req_body = {"Data": $data, "Risk": $risk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Account Access Consents
#
# DELETE /account-access-consents/{ConsentId}
# operationId: DeleteAccountAccessConsentsConsentId
export def "account-access-consents delete" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/account-access-consents/{consent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Account Access Consents
#
# GET /account-access-consents/{ConsentId}
# operationId: GetAccountAccessConsentsConsentId
export def "account-access-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consent_id | is-empty) { error make --unspanned { msg: "path parameter 'ConsentId' must be non-empty" } }
  let full_url = (build-url $base ({consent_id: (encode-path-segment $consent_id)} | format pattern "/account-access-consents/{consent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Accounts
#
# GET /accounts
# operationId: GetAccounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Accounts
#
# GET /accounts/{AccountId}
# operationId: GetAccountsAccountId
export def "accounts get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Balances
#
# GET /accounts/{AccountId}/balances
# operationId: GetAccountsAccountIdBalances
export def "accounts-balances get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/balances"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Beneficiaries
#
# GET /accounts/{AccountId}/beneficiaries
# operationId: GetAccountsAccountIdBeneficiaries
export def "accounts-beneficiaries get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/beneficiaries"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Direct Debits
#
# GET /accounts/{AccountId}/direct-debits
# operationId: GetAccountsAccountIdDirectDebits
export def "accounts-direct-debits get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/direct-debits"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Offers
#
# GET /accounts/{AccountId}/offers
# operationId: GetAccountsAccountIdOffers
export def "accounts-offers get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/offers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Parties
#
# GET /accounts/{AccountId}/parties
# operationId: GetAccountsAccountIdParties
export def "accounts-parties get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/parties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Parties
#
# GET /accounts/{AccountId}/party
# operationId: GetAccountsAccountIdParty
export def "accounts-party get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/party"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Products
#
# GET /accounts/{AccountId}/product
# operationId: GetAccountsAccountIdProduct
export def "accounts-product get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/product"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Scheduled Payments
#
# GET /accounts/{AccountId}/scheduled-payments
# operationId: GetAccountsAccountIdScheduledPayments
export def "accounts-scheduled-payments get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/scheduled-payments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Standing Orders
#
# GET /accounts/{AccountId}/standing-orders
# operationId: GetAccountsAccountIdStandingOrders
export def "accounts-standing-orders get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/standing-orders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Statements
#
# GET /accounts/{AccountId}/statements
# operationId: GetAccountsAccountIdStatements
export def "accounts-statements list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-statement-date-time: string # The UTC ISO 8601 Date Time to filter statements FROM NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (format: date-time)
  --to-statement-date-time: string # The UTC ISO 8601 Date Time to filter statements TO NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (format: date-time)
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let qp = [(serialize-qp "fromStatementDateTime" $from_statement_date_time "scalar") (serialize-qp "toStatementDateTime" $to_statement_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/statements") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromStatementDateTime": $from_statement_date_time, "toStatementDateTime": $to_statement_date_time} | compact), body: null}
}

# Get Statements
#
# GET /accounts/{AccountId}/statements/{StatementId}
# operationId: GetAccountsAccountIdStatementsStatementId
export def "accounts-statements get" [
  account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'StatementId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), statement_id: (encode-path-segment $statement_id)} | format pattern "/accounts/{account_id}/statements/{statement_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Statements
#
# GET /accounts/{AccountId}/statements/{StatementId}/file
# operationId: GetAccountsAccountIdStatementsStatementIdFile
export def "accounts-statements-file get" [
  account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'StatementId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), statement_id: (encode-path-segment $statement_id)} | format pattern "/accounts/{account_id}/statements/{statement_id}/file"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Transactions
#
# GET /accounts/{AccountId}/statements/{StatementId}/transactions
# operationId: GetAccountsAccountIdStatementsStatementIdTransactions
export def "accounts-statements-transactions get" [
  account_id: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'StatementId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), statement_id: (encode-path-segment $statement_id)} | format pattern "/accounts/{account_id}/statements/{statement_id}/transactions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Transactions
#
# GET /accounts/{AccountId}/transactions
# operationId: GetAccountsAccountIdTransactions
export def "accounts-transactions get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-booking-date-time: string # The UTC ISO 8601 Date Time to filter transactions FROM NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (format: date-time)
  --to-booking-date-time: string # The UTC ISO 8601 Date Time to filter transactions TO NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (format: date-time)
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'AccountId' must be non-empty" } }
  let qp = [(serialize-qp "fromBookingDateTime" $from_booking_date_time "scalar") (serialize-qp "toBookingDateTime" $to_booking_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromBookingDateTime": $from_booking_date_time, "toBookingDateTime": $to_booking_date_time} | compact), body: null}
}

# Get Balances
#
# GET /balances
# operationId: GetBalances
export def "balances get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/balances")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Beneficiaries
#
# GET /beneficiaries
# operationId: GetBeneficiaries
export def "beneficiaries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beneficiaries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Direct Debits
#
# GET /direct-debits
# operationId: GetDirectDebits
export def "direct-debits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/direct-debits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Offers
#
# GET /offers
# operationId: GetOffers
export def "offers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/offers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Parties
#
# GET /party
# operationId: GetParty
export def "party get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/party")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Products
#
# GET /products
# operationId: GetProducts
export def "products get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Scheduled Payments
#
# GET /scheduled-payments
# operationId: GetScheduledPayments
export def "scheduled-payments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scheduled-payments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Standing Orders
#
# GET /standing-orders
# operationId: GetStandingOrders
export def "standing-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/standing-orders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Statements
#
# GET /statements
# operationId: GetStatements
export def "statements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-statement-date-time: string # The UTC ISO 8601 Date Time to filter statements FROM NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (format: date-time)
  --to-statement-date-time: string # The UTC ISO 8601 Date Time to filter statements TO NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (format: date-time)
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromStatementDateTime" $from_statement_date_time "scalar") (serialize-qp "toStatementDateTime" $to_statement_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromStatementDateTime": $from_statement_date_time, "toStatementDateTime": $to_statement_date_time} | compact), body: null}
}

# Get Transactions
#
# GET /transactions
# operationId: GetTransactions
export def "transactions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-booking-date-time: string # The UTC ISO 8601 Date Time to filter transactions FROM NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (format: date-time)
  --to-booking-date-time: string # The UTC ISO 8601 Date Time to filter transactions TO NB Time component is optional - set to 00:00:00 for just Date. If the Date Time contains a timezone, the ASPSP must ignore the timezone component. (format: date-time)
  --x-fapi-auth-date: string # The time when the PSU last logged in with the TPP. All dates in the HTTP headers are represented as RFC 7231 Full Dates. An example is below: Sun, 10 Sep 2017 19:43:31 UTC
  --x-fapi-customer-ip-address: string # The PSU's IP address if the PSU is currently logged in with the TPP.
  --x-fapi-interaction-id: string # An RFC4122 UID used as a correlation id.
  --authorization: string # An Authorisation Token as per https://tools.ietf.org/html/rfc6750
  --x-customer-user-agent: string # Indicates the user-agent that the PSU is using.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromBookingDateTime" $from_booking_date_time "scalar") (serialize-qp "toBookingDateTime" $to_booking_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-fapi-auth-date": $x_fapi_auth_date, "x-fapi-customer-ip-address": $x_fapi_customer_ip_address, "x-fapi-interaction-id": $x_fapi_interaction_id, "Authorization": $authorization, "x-customer-user-agent": $x_customer_user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromBookingDateTime": $from_booking_date_time, "toBookingDateTime": $to_booking_date_time} | compact), body: null}
}
