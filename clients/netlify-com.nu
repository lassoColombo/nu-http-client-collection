# Auto-generated client for Netlify's API documentation v2.15.0
# Source: https://api.apis.guru/v2/specs/netlify.com/2.15.0/swagger.json
# Auth: --token flag or $env.NETLIFY_S_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.netlify.com/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o NETLIFY_S_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
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
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
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

def base-url-completer [] { ["https://api.netlify.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def period-completer [] { ["monthly" "yearly"] }
def context-name-completer [] { ["all" "branch-deploy" "deploy-preview" "dev" "production"] }
def scope-completer [] { ["builds" "functions" "post-processing" "runtime"] }
def context-completer [] { ["branch-deploy" "deploy-preview" "dev" "production"] }
def section-completer [] { ["building" "cleanup" "deploying" "initializing" "postprocessing"] }
def filter-completer [] { ["all" "guest" "owner"] }
def state-completer [] { ["accepted" "building" "enqueued" "error" "new" "pending_review" "prepared" "preparing" "processing" "ready" "rejected" "retrying" "uploaded" "uploading"] }
def role-completer [] { ["Collaborator" "Controller" "Owner"] }
def site-access-completer [] { ["all" "none" "selected"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-accounts-for-user" "create-account" "list-account-types-for-user" "cancel-account" "get-account" "update-account" "list-account-audit-events" "get-env-vars" "create-env-vars" "delete-env-var" "get-env-var" "set-env-var-value" "update-env-var" "delete-env-var-value" "list-payment-methods-for-user" "get-site-build" "update-site-build-log" "notify-build-start" "list-deploy-keys" "create-deploy-key" "delete-deploy-key" "get-deploy-key" "delete-deploy" "get-deploy" "cancel-site-deploy" "upload-deploy-file" "upload-deploy-function" "lock-deploy" "create-plugin-run" "unlock-deploy" "get-dns-zones" "create-dns-zone" "delete-dns-zone" "get-dns-zone" "get-dns-records" "create-dns-record" "delete-dns-record" "get-individual-dns-record" "transfer-dns-zone" "list-form-submissions" "list-hooks-by-site-id" "create-hook-by-site-id" "list-hook-types" "delete-hook" "get-hook" "update-hook" "enable-hook" "create-ticket" "show-ticket" "exchange-ticket" "get-services" "show-service" "show-service-manifest" "list-sites" "create-site" "delete-site" "get-site" "update-site" "list-site-assets" "create-site-asset" "delete-site-asset" "get-site-asset-info" "update-site-asset" "get-site-asset-public-signature" "list-site-build-hooks" "create-site-build-hook" "delete-site-build-hook" "get-site-build-hook" "update-site-build-hook" "list-site-builds" "create-site-build" "list-site-deployed-branches" "list-site-deploys" "create-site-deploy" "delete-site-deploy" "get-site-deploy" "update-site-deploy" "restore-site-deploy" "get-dns-for-site" "configure-dns-for-site" "list-site-files" "get-site-file-by-path-name" "list-site-forms" "delete-site-form" "get-site-metadata" "update-site-metadata" "get-latest-plugin-runs" "update-plugin" "rollback-site-deploy" "list-service-instances-for-site" "create-service-instance" "delete-service-instance" "show-service-instance" "update-service-instance" "list-site-snippets" "create-site-snippet" "delete-site-snippet" "get-site-snippet" "update-site-snippet" "show-site-tls-certificate" "provision-site-tls-certificate" "list-site-submissions" "get-split-tests" "create-split-test" "get-split-test" "update-split-test" "enable-split-test" "disable-split-test" "unlink-site-repo" "delete-submission" "list-form-submission" "get-current-user" "get-account-build-status" "list-members-for-account" "add-member-to-account" "remove-account-member" "get-account-member" "update-account-member" "list-sites-for-account" "create-site-in-team" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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

# GET /accounts
#
# operationId: listAccountsForUser
export def "list-accounts-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts" $auth.query)
  let accept_val = "application/json"
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

# POST /accounts
#
# operationId: createAccount
export def "create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extra-seats-block: int
  name: string
  --payment-method-id: string
  --period: string@period-completer
  type_id: string
]: any -> oneof<record<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record<included: int, used: int>, sites: record<included: int, used: int>>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts" $auth.query)
  let req_body = {"extra_seats_block": $extra_seats_block, "name": $name, "payment_method_id": $payment_method_id, "period": $period, "type_id": $type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# GET /accounts/types
#
# operationId: listAccountTypesForUser
export def "list-account-types-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<capabilities: record, description: string, id: string, monthly_dollar_price: int, monthly_seats_addon_dollar_price: int, name: string, yearly_dollar_price: int, yearly_seats_addon_dollar_price: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/types" $auth.query)
  let accept_val = "application/json"
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

# DELETE /accounts/{account_id}
#
# operationId: cancelAccount
export def "cancel-account" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $auth.query)
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

# GET /accounts/{account_id}
#
# operationId: getAccount
export def "get-account" [
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
]: nothing -> oneof<table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /accounts/{account_id}
#
# operationId: updateAccount
export def "update-account" [
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
  --billing-details: string
  --billing-email: string
  --billing-name: string
  --extra-seats-block: int
  --name: string
  --slug: string
  --type-id: string
]: any -> oneof<record<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record<included: int, used: int>, sites: record<included: int, used: int>>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $auth.query)
  let req_body = {"billing_details": $billing_details, "billing_email": $billing_email, "billing_name": $billing_name, "extra_seats_block": $extra_seats_block, "name": $name, "slug": $slug, "type_id": $type_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# GET /accounts/{account_id}/audit
#
# operationId: listAccountAuditEvents
export def "list-account-audit-events" [
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
  --query: string
  --log-type: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<table<account_id: string, id: string, payload: record<action: string, actor_email: string, actor_id: string, actor_name: string, log_type: string, timestamp: string>>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "log_type" $log_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/audit") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "log_type": $log_type, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all environment variables for an account or site. An account corresponds to a team in the Netlify UI. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# GET /accounts/{account_id}/env
# operationId: getEnvVars
export def "get-env-vars" [
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
  --context-name: string@context-name-completer # Filter by deploy context
  --scope: string@scope-completer # Filter by scope
  --site-id: string # If specified, only return environment variables set on this site
]: nothing -> oneof<table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let qp = [(serialize-qp "context_name" $context_name "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/env") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"context_name": $context_name, "scope": $scope, "site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates new environment variables. Granular scopes are available on Pro plans and above. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# POST /accounts/{account_id}/env
# operationId: createEnvVars
export def "create-env-vars" [
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
  --site-id: string # If provided, create an environment variable on the site level, not the account level
  --body: list
]: any -> oneof<table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/env") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"site_id": $site_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Deletes an environment variable. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# DELETE /accounts/{account_id}/env/{key}
# operationId: deleteEnvVar
export def "delete-env-var" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, delete the environment variable from this site
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key)} | format pattern "/accounts/{account_id}/env/{key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns an individual environment variable. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# GET /accounts/{account_id}/env/{key}
# operationId: getEnvVar
export def "get-env-var" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, return the environment variable for a specific site (no merging is performed)
]: nothing -> oneof<record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key)} | format pattern "/accounts/{account_id}/env/{key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates or creates a new value for an existing environment variable. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# PATCH /accounts/{account_id}/env/{key}
# operationId: setEnvVarValue
export def "set-env-var-value" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, update an environment variable set on this site
  --context: string@context-completer # The deploy context in which this value will be used. `dev` refers to local development when running `netlify dev`.
  --value: string # The environment variable's unencrypted value
]: any -> oneof<record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key)} | format pattern "/accounts/{account_id}/env/{key}") $qp $auth.query)
  let req_body = {"context": $context, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"site_id": $site_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Updates an existing environment variable and all of its values. Existing values will be replaced by values provided. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# PUT /accounts/{account_id}/env/{key}
# operationId: updateEnvVar
export def "update-env-var" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, update an environment variable set on this site
  --body-key: string # The existing or new name of the key, if you wish to rename it (case-sensitive)
  --scopes: list<string> # The scopes that this environment variable is set to (Pro plans and above)
  --values: list # item shape: {context?: "all"|"dev"|"branch-deploy"|"deploy-preview"|"production", id?: string, value?: string}
]: any -> oneof<record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key)} | format pattern "/accounts/{account_id}/env/{key}") $qp $auth.query)
  let req_body = {"key": $body_key, "scopes": $scopes, "values": $values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"site_id": $site_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a specific environment variable value. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# DELETE /accounts/{account_id}/env/{key}/value/{id}
# operationId: deleteEnvVarValue
export def "delete-env-var-value" [
  account_id: string
  key: string
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
  --site-id: string # If provided, delete the value from an environment variable on this site
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), key: (encode-path-segment $key), id: (encode-path-segment $id)} | format pattern "/accounts/{account_id}/env/{key}/value/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /billing/payment_methods
#
# operationId: listPaymentMethodsForUser
export def "list-payment-methods-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<created_at: string, data: record<card_type: string, email: string, last4: string>, id: string, method_name: string, state: string, type: string, updated_at: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing/payment_methods" $auth.query)
  let accept_val = "application/json"
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

# GET /builds/{build_id}
#
# operationId: getSiteBuild
export def "get-site-build" [
  build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({build_id: (encode-path-segment $build_id)} | format pattern "/builds/{build_id}") $auth.query)
  let accept_val = "application/json"
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

# POST /builds/{build_id}/log
#
# operationId: updateSiteBuildLog
export def "update-site-build-log" [
  build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --error: oneof<nothing, bool>
  --message: string
  --section: string@section-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({build_id: (encode-path-segment $build_id)} | format pattern "/builds/{build_id}/log") $auth.query)
  let req_body = {"error": $error, "message": $message, "section": $section} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# POST /builds/{build_id}/start
#
# operationId: notifyBuildStart
export def "notify-build-start" [
  build_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($build_id | is-empty) { error make --unspanned { msg: "path parameter 'build_id' must be non-empty" } }
  let full_url = (build-url $base ({build_id: (encode-path-segment $build_id)} | format pattern "/builds/{build_id}/start") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# GET /deploy_keys
#
# operationId: listDeployKeys
export def "list-deploy-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<created_at: string, id: string, public_key: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy_keys" $auth.query)
  let accept_val = "application/json"
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

# POST /deploy_keys
#
# operationId: createDeployKey
export def "create-deploy-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<created_at: string, id: string, public_key: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy_keys" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# DELETE /deploy_keys/{key_id}
#
# operationId: deleteDeployKey
export def "delete-deploy-key" [
  key_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({key_id: (encode-path-segment $key_id)} | format pattern "/deploy_keys/{key_id}") $auth.query)
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

# GET /deploy_keys/{key_id}
#
# operationId: getDeployKey
export def "get-deploy-key" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<created_at: string, id: string, public_key: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({key_id: (encode-path-segment $key_id)} | format pattern "/deploy_keys/{key_id}") $auth.query)
  let accept_val = "application/json"
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

# DELETE /deploys/{deploy_id}
#
# operationId: deleteDeploy
export def "delete-deploy" [
  deploy_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}") $auth.query)
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

# GET /deploys/{deploy_id}
#
# operationId: getDeploy
export def "get-deploy" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}") $auth.query)
  let accept_val = "application/json"
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

# POST /deploys/{deploy_id}/cancel
#
# operationId: cancelSiteDeploy
export def "cancel-site-deploy" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}/cancel") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# PUT /deploys/{deploy_id}/files/{path}
#
# operationId: uploadDeployFile
export def "upload-deploy-file" [
  deploy_id: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --size: int
  --body: string
]: any -> oneof<record<id: string, mime_type: string, path: string, sha: string, size: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id), path: (encode-path-segment $path)} | format pattern "/deploys/{deploy_id}/files/{path}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"size": $size} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/octet-stream"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# PUT /deploys/{deploy_id}/functions/{name}
#
# operationId: uploadDeployFunction
export def "upload-deploy-function" [
  deploy_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --runtime: string
  --size: int
  --x-nf-retry-count: int
  --body: string
]: any -> oneof<record<id: string, name: string, sha: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "runtime" $runtime "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id), name: (encode-path-segment $name)} | format pattern "/deploys/{deploy_id}/functions/{name}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Nf-Retry-Count": $x_nf_retry_count} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"runtime": $runtime, "size": $size} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/octet-stream"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# POST /deploys/{deploy_id}/lock
#
# operationId: lockDeploy
export def "lock-deploy" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}/lock") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# This is an internal-only endpoint.
#
# POST /deploys/{deploy_id}/plugin_runs
# operationId: createPluginRun
export def "create-plugin-run" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package: string
  --reporting-event: string
  --state: string
  --summary: string
  --text: string
  --title: string
  --version: string
]: any -> oneof<record<package: string, reporting_event: string, state: string, summary: string, text: string, title: string, version: string, deploy_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}/plugin_runs") $auth.query)
  let req_body = {"package": $package, "reporting_event": $reporting_event, "state": $state, "summary": $summary, "text": $text, "title": $title, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# POST /deploys/{deploy_id}/unlock
#
# operationId: unlockDeploy
export def "unlock-deploy" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({deploy_id: (encode-path-segment $deploy_id)} | format pattern "/deploys/{deploy_id}/unlock") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# GET /dns_zones
#
# operationId: getDnsZones
export def "get-dns-zones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-slug: string
]: nothing -> oneof<table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_slug" $account_slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dns_zones" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"account_slug": $account_slug} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /dns_zones
#
# operationId: createDnsZone
export def "create-dns-zone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-slug: string
  --name: string
  --site-id: string
]: any -> oneof<record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dns_zones" $auth.query)
  let req_body = {"account_slug": $account_slug, "name": $name, "site_id": $site_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# DELETE /dns_zones/{zone_id}
#
# operationId: deleteDnsZone
export def "delete-dns-zone" [
  zone_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}") $auth.query)
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

# GET /dns_zones/{zone_id}
#
# operationId: getDnsZone
export def "get-dns-zone" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}") $auth.query)
  let accept_val = "application/json"
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

# GET /dns_zones/{zone_id}/dns_records
#
# operationId: getDnsRecords
export def "get-dns-records" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}/dns_records") $auth.query)
  let accept_val = "application/json"
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

# POST /dns_zones/{zone_id}/dns_records
#
# operationId: createDnsRecord
export def "create-dns-record" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flag: int # format: int64
  --hostname: string
  --port: int # format: int64
  --priority: int # format: int64
  --tag: string
  --ttl: int # format: int64
  --type: string
  --value: string
  --weight: int # format: int64
]: any -> oneof<record<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}/dns_records") $auth.query)
  let req_body = {"flag": $flag, "hostname": $hostname, "port": $port, "priority": $priority, "tag": $tag, "ttl": $ttl, "type": $type, "value": $value, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# DELETE /dns_zones/{zone_id}/dns_records/{dns_record_id}
#
# operationId: deleteDnsRecord
export def "delete-dns-record" [
  zone_id: string
  dns_record_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($dns_record_id | is-empty) { error make --unspanned { msg: "path parameter 'dns_record_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id), dns_record_id: (encode-path-segment $dns_record_id)} | format pattern "/dns_zones/{zone_id}/dns_records/{dns_record_id}") $auth.query)
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

# GET /dns_zones/{zone_id}/dns_records/{dns_record_id}
#
# operationId: getIndividualDnsRecord
export def "get-individual-dns-record" [
  zone_id: string
  dns_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($dns_record_id | is-empty) { error make --unspanned { msg: "path parameter 'dns_record_id' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id), dns_record_id: (encode-path-segment $dns_record_id)} | format pattern "/dns_zones/{zone_id}/dns_records/{dns_record_id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /dns_zones/{zone_id}/transfer
#
# operationId: transferDnsZone
export def "transfer-dns-zone" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # the account of the dns zone (required)
  --transfer-account-id: string # the account you want to transfer the dns zone to (required)
  --transfer-user-id: string # the user you want to transfer the dns zone to (required)
]: nothing -> oneof<record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($account_id == null) { error make --unspanned { msg: "required query parameter 'account_id' missing: pass --account-id" } }
  if ($transfer_account_id == null) { error make --unspanned { msg: "required query parameter 'transfer_account_id' missing: pass --transfer-account-id" } }
  if ($transfer_user_id == null) { error make --unspanned { msg: "required query parameter 'transfer_user_id' missing: pass --transfer-user-id" } }
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "transfer_account_id" $transfer_account_id "scalar") (serialize-qp "transfer_user_id" $transfer_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/dns_zones/{zone_id}/transfer") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"account_id": $account_id, "transfer_account_id": $transfer_account_id, "transfer_user_id": $transfer_user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# GET /forms/{form_id}/submissions
#
# operationId: listFormSubmissions
export def "list-form-submissions" [
  form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($form_id | is-empty) { error make --unspanned { msg: "path parameter 'form_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({form_id: (encode-path-segment $form_id)} | format pattern "/forms/{form_id}/submissions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /hooks
#
# operationId: listHooksBySiteId
export def "list-hooks-by-site-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # required
]: nothing -> oneof<table<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id == null) { error make --unspanned { msg: "required query parameter 'site_id' missing: pass --site-id" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"site_id": $site_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /hooks
#
# operationId: createHookBySiteId
export def "create-hook-by-site-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # required
  --created-at: string # format: dateTime
  --data: record
  --disabled: oneof<nothing, bool>
  --event: string
  --id: string
  --site-id-body: string # (body field)
  --type: string
  --updated-at: string # format: dateTime
]: any -> oneof<record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id == null) { error make --unspanned { msg: "required query parameter 'site_id' missing: pass --site-id" } }
  let qp = [(serialize-qp "site_id" $site_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp $auth.query)
  let req_body = {"created_at": $created_at, "data": $data, "disabled": $disabled, "event": $event, "id": $id, "site_id": $site_id_body, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"site_id": $site_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# GET /hooks/types
#
# operationId: listHookTypes
export def "list-hook-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<events: list<string>, fields: list<record>, name: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hooks/types" $auth.query)
  let accept_val = "application/json"
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

# DELETE /hooks/{hook_id}
#
# operationId: deleteHook
export def "delete-hook" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/hooks/{hook_id}") $auth.query)
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

# GET /hooks/{hook_id}
#
# operationId: getHook
export def "get-hook" [
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
]: nothing -> oneof<record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/hooks/{hook_id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /hooks/{hook_id}
#
# operationId: updateHook
export def "update-hook" [
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
  --created-at: string # format: dateTime
  --data: record
  --disabled: oneof<nothing, bool>
  --event: string
  --id: string
  --site-id: string
  --type: string
  --updated-at: string # format: dateTime
]: any -> oneof<record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/hooks/{hook_id}") $auth.query)
  let req_body = {"created_at": $created_at, "data": $data, "disabled": $disabled, "event": $event, "id": $id, "site_id": $site_id, "type": $type, "updated_at": $updated_at} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# POST /hooks/{hook_id}/enable
#
# operationId: enableHook
export def "enable-hook" [
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
]: nothing -> oneof<record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hook_id | is-empty) { error make --unspanned { msg: "path parameter 'hook_id' must be non-empty" } }
  let full_url = (build-url $base ({hook_id: (encode-path-segment $hook_id)} | format pattern "/hooks/{hook_id}/enable") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# POST /oauth/tickets
#
# operationId: createTicket
export def "create-ticket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # required
]: nothing -> oneof<record<authorized: bool, client_id: string, created_at: string, id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id == null) { error make --unspanned { msg: "required query parameter 'client_id' missing: pass --client-id" } }
  let qp = [(serialize-qp "client_id" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/tickets" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"client_id": $client_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# GET /oauth/tickets/{ticket_id}
#
# operationId: showTicket
export def "show-ticket" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<authorized: bool, client_id: string, created_at: string, id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticket_id' must be non-empty" } }
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/oauth/tickets/{ticket_id}") $auth.query)
  let accept_val = "application/json"
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

# POST /oauth/tickets/{ticket_id}/exchange
#
# operationId: exchangeTicket
export def "exchange-ticket" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<access_token: string, created_at: string, id: string, user_email: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticket_id' must be non-empty" } }
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/oauth/tickets/{ticket_id}/exchange") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# GET /services/
#
# operationId: getServices
export def "get-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
]: nothing -> oneof<table<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /services/{addonName}
#
# operationId: showService
export def "show-service" [
  addon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($addon_name | is-empty) { error make --unspanned { msg: "path parameter 'addonName' must be non-empty" } }
  let full_url = (build-url $base ({addon_name: (encode-path-segment $addon_name)} | format pattern "/services/{addon_name}") $auth.query)
  let accept_val = "application/json"
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

# GET /services/{addonName}/manifest
#
# operationId: showServiceManifest
export def "show-service-manifest" [
  addon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($addon_name | is-empty) { error make --unspanned { msg: "path parameter 'addonName' must be non-empty" } }
  let full_url = (build-url $base ({addon_name: (encode-path-segment $addon_name)} | format pattern "/services/{addon_name}/manifest") $auth.query)
  let accept_val = "application/json"
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
  send-get $req $insecure $raw $allow_errors $full [201]
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /sites
# operationId: listSites
export def "list-sites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --filter: string@filter-completer
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<table<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record, html: record, images: record, js: record, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list, id: string, locked: bool, name: string, published_at: string, required: list, required_functions: list, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "filter": $filter, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /sites
# operationId: createSite
export def "create-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configure-dns: oneof<nothing, bool>
  --account-name: string
  --account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list<string>
  --force-ssl: oneof<nothing, bool>
  --git-provider: string
  --id: string
  --id-domain: string
  --managed-dns: oneof<nothing, bool>
  --name: string
  --notification-email: string
  --password: string
  --plan: string
  --prerender: string
  --processing-settings: record # shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> oneof<record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configure_dns" $configure_dns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp $auth.query)
  let req_body = {"account_name": $account_name, "account_slug": $account_slug, "admin_url": $admin_url, "build_image": $build_image, "build_settings": $build_settings, "capabilities": $capabilities, "created_at": $created_at, "custom_domain": $custom_domain, "default_hooks_data": $default_hooks_data, "deploy_hook": $deploy_hook, "deploy_url": $deploy_url, "domain_aliases": $domain_aliases, "force_ssl": $force_ssl, "git_provider": $git_provider, "id": $id, "id_domain": $id_domain, "managed_dns": $managed_dns, "name": $name, "notification_email": $notification_email, "password": $password, "plan": $plan, "prerender": $prerender, "processing_settings": $processing_settings, "published_deploy": $published_deploy, "screenshot_url": $screenshot_url, "session_id": $session_id, "ssl": $ssl, "ssl_url": $ssl_url, "state": $state, "updated_at": $updated_at, "url": $url, "user_id": $user_id, "repo": $repo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"configure_dns": $configure_dns} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# DELETE /sites/{site_id}
#
# operationId: deleteSite
export def "delete-site" [
  site_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}") $auth.query)
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

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /sites/{site_id}
# operationId: getSite
export def "get-site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}") $auth.query)
  let accept_val = "application/json"
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

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [updateEnvVar](#tag/environmentVariables/operation/updateEnvVar) to update a site's environment variables.
#
# PATCH /sites/{site_id}
# operationId: updateSite
export def "update-site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list<string>
  --force-ssl: oneof<nothing, bool>
  --git-provider: string
  --id: string
  --id-domain: string
  --managed-dns: oneof<nothing, bool>
  --name: string
  --notification-email: string
  --password: string
  --plan: string
  --prerender: string
  --processing-settings: record # shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> oneof<record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}") $auth.query)
  let req_body = {"account_name": $account_name, "account_slug": $account_slug, "admin_url": $admin_url, "build_image": $build_image, "build_settings": $build_settings, "capabilities": $capabilities, "created_at": $created_at, "custom_domain": $custom_domain, "default_hooks_data": $default_hooks_data, "deploy_hook": $deploy_hook, "deploy_url": $deploy_url, "domain_aliases": $domain_aliases, "force_ssl": $force_ssl, "git_provider": $git_provider, "id": $id, "id_domain": $id_domain, "managed_dns": $managed_dns, "name": $name, "notification_email": $notification_email, "password": $password, "plan": $plan, "prerender": $prerender, "processing_settings": $processing_settings, "published_deploy": $published_deploy, "screenshot_url": $screenshot_url, "session_id": $session_id, "ssl": $ssl, "ssl_url": $ssl_url, "state": $state, "updated_at": $updated_at, "url": $url, "user_id": $user_id, "repo": $repo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# GET /sites/{site_id}/assets
#
# operationId: listSiteAssets
export def "list-site-assets" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/assets") $auth.query)
  let accept_val = "application/json"
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

# POST /sites/{site_id}/assets
#
# operationId: createSiteAsset
export def "create-site-asset" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # required
  --size: int # required, format: int64
  --content-type: string # required
  --visibility: string
]: nothing -> oneof<record<asset: record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>, form: record<fields: record, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($name == null) { error make --unspanned { msg: "required query parameter 'name' missing: pass --name" } }
  if ($size == null) { error make --unspanned { msg: "required query parameter 'size' missing: pass --size" } }
  if ($content_type == null) { error make --unspanned { msg: "required query parameter 'content_type' missing: pass --content-type" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/assets") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"name": $name, "size": $size, "content_type": $content_type, "visibility": $visibility} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# DELETE /sites/{site_id}/assets/{asset_id}
#
# operationId: deleteSiteAsset
export def "delete-site-asset" [
  site_id: string
  asset_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'asset_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), asset_id: (encode-path-segment $asset_id)} | format pattern "/sites/{site_id}/assets/{asset_id}") $auth.query)
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

# GET /sites/{site_id}/assets/{asset_id}
#
# operationId: getSiteAssetInfo
export def "get-site-asset-info" [
  site_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'asset_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), asset_id: (encode-path-segment $asset_id)} | format pattern "/sites/{site_id}/assets/{asset_id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /sites/{site_id}/assets/{asset_id}
#
# operationId: updateSiteAsset
export def "update-site-asset" [
  site_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # required
]: nothing -> oneof<record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'asset_id' must be non-empty" } }
  if ($state == null) { error make --unspanned { msg: "required query parameter 'state' missing: pass --state" } }
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), asset_id: (encode-path-segment $asset_id)} | format pattern "/sites/{site_id}/assets/{asset_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"state": $state} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# GET /sites/{site_id}/assets/{asset_id}/public_signature
#
# operationId: getSiteAssetPublicSignature
export def "get-site-asset-public-signature" [
  site_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'asset_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), asset_id: (encode-path-segment $asset_id)} | format pattern "/sites/{site_id}/assets/{asset_id}/public_signature") $auth.query)
  let accept_val = "application/json"
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

# GET /sites/{site_id}/build_hooks
#
# operationId: listSiteBuildHooks
export def "list-site-build-hooks" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<branch: string, created_at: string, id: string, site_id: string, title: string, url: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/build_hooks") $auth.query)
  let accept_val = "application/json"
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

# POST /sites/{site_id}/build_hooks
#
# operationId: createSiteBuildHook
export def "create-site-build-hook" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string
  --title: string
]: any -> oneof<record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/build_hooks") $auth.query)
  let req_body = {"branch": $branch, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# DELETE /sites/{site_id}/build_hooks/{id}
#
# operationId: deleteSiteBuildHook
export def "delete-site-build-hook" [
  site_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), id: (encode-path-segment $id)} | format pattern "/sites/{site_id}/build_hooks/{id}") $auth.query)
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

# GET /sites/{site_id}/build_hooks/{id}
#
# operationId: getSiteBuildHook
export def "get-site-build-hook" [
  site_id: string
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
]: nothing -> oneof<record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), id: (encode-path-segment $id)} | format pattern "/sites/{site_id}/build_hooks/{id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /sites/{site_id}/build_hooks/{id}
#
# operationId: updateSiteBuildHook
export def "update-site-build-hook" [
  site_id: string
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
  --branch: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), id: (encode-path-segment $id)} | format pattern "/sites/{site_id}/build_hooks/{id}") $auth.query)
  let req_body = {"branch": $branch, "title": $title} | compact
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

# GET /sites/{site_id}/builds
#
# operationId: listSiteBuilds
export def "list-site-builds" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<table<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/builds") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /sites/{site_id}/builds
#
# operationId: createSiteBuild
export def "create-site-build" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-cache: oneof<nothing, bool>
  --image: string
]: any -> oneof<record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/builds") $auth.query)
  let req_body = {"clear_cache": $clear_cache, "image": $image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# GET /sites/{site_id}/deployed-branches
#
# operationId: listSiteDeployedBranches
export def "list-site-deployed-branches" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<deploy_id: string, id: string, name: string, slug: string, ssl_url: string, url: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/deployed-branches") $auth.query)
  let accept_val = "application/json"
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

# GET /sites/{site_id}/deploys
#
# operationId: listSiteDeploys
export def "list-site-deploys" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploy-previews: oneof<nothing, bool>
  --production: oneof<nothing, bool>
  --state: string@state-completer
  --branch: string
  --latest-published: oneof<nothing, bool>
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<table<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "deploy-previews" $deploy_previews "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "latest-published" $latest_published "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/deploys") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"deploy-previews": $deploy_previews, "production": $production, "state": $state, "branch": $branch, "latest-published": $latest_published, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /sites/{site_id}/deploys
#
# operationId: createSiteDeploy
export def "create-site-deploy" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploy-previews: oneof<nothing, bool>
  --production: oneof<nothing, bool>
  --state: string@state-completer
  --branch: string
  --latest-published: oneof<nothing, bool>
  --title: string
  --async: oneof<nothing, bool>
  --branch-body: string # (body field)
  --draft: oneof<nothing, bool>
  --files: record
  --framework: string
  --function-schedules: list # item shape: {cron?: string, name?: string}
  --functions: record
  --functions-config: record
]: any -> oneof<record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "deploy-previews" $deploy_previews "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "latest-published" $latest_published "scalar") (serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/deploys") $qp $auth.query)
  let req_body = {"async": $async, "branch": $branch_body, "draft": $draft, "files": $files, "framework": $framework, "function_schedules": $function_schedules, "functions": $functions, "functions_config": $functions_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"deploy-previews": $deploy_previews, "production": $production, "state": $state, "branch": $branch, "latest-published": $latest_published, "title": $title} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DELETE /sites/{site_id}/deploys/{deploy_id}
#
# operationId: deleteSiteDeploy
export def "delete-site-deploy" [
  site_id: string
  deploy_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), deploy_id: (encode-path-segment $deploy_id)} | format pattern "/sites/{site_id}/deploys/{deploy_id}") $auth.query)
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

# GET /sites/{site_id}/deploys/{deploy_id}
#
# operationId: getSiteDeploy
export def "get-site-deploy" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), deploy_id: (encode-path-segment $deploy_id)} | format pattern "/sites/{site_id}/deploys/{deploy_id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /sites/{site_id}/deploys/{deploy_id}
#
# operationId: updateSiteDeploy
export def "update-site-deploy" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool>
  --branch: string
  --draft: oneof<nothing, bool>
  --files: record
  --framework: string
  --function-schedules: list # item shape: {cron?: string, name?: string}
  --functions: record
  --functions-config: record
]: any -> oneof<record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), deploy_id: (encode-path-segment $deploy_id)} | format pattern "/sites/{site_id}/deploys/{deploy_id}") $auth.query)
  let req_body = {"async": $async, "branch": $branch, "draft": $draft, "files": $files, "framework": $framework, "function_schedules": $function_schedules, "functions": $functions, "functions_config": $functions_config} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# POST /sites/{site_id}/deploys/{deploy_id}/restore
#
# operationId: restoreSiteDeploy
export def "restore-site-deploy" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($deploy_id | is-empty) { error make --unspanned { msg: "path parameter 'deploy_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), deploy_id: (encode-path-segment $deploy_id)} | format pattern "/sites/{site_id}/deploys/{deploy_id}/restore") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# GET /sites/{site_id}/dns
#
# operationId: getDNSForSite
export def "get-dns-for-site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/dns") $auth.query)
  let accept_val = "application/json"
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

# PUT /sites/{site_id}/dns
#
# operationId: configureDNSForSite
export def "configure-dns-for-site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/dns") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# GET /sites/{site_id}/files
#
# operationId: listSiteFiles
export def "list-site-files" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<id: string, mime_type: string, path: string, sha: string, size: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/files") $auth.query)
  let accept_val = "application/json"
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

# GET /sites/{site_id}/files/{file_path}
#
# operationId: getSiteFileByPathName
export def "get-site-file-by-path-name" [
  site_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<id: string, mime_type: string, path: string, sha: string, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($file_path | is-empty) { error make --unspanned { msg: "path parameter 'file_path' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), file_path: (encode-path-segment $file_path)} | format pattern "/sites/{site_id}/files/{file_path}") $auth.query)
  let accept_val = "application/json"
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

# GET /sites/{site_id}/forms
#
# operationId: listSiteForms
export def "list-site-forms" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<created_at: string, fields: list<record>, id: string, name: string, paths: list<string>, site_id: string, submission_count: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/forms") $auth.query)
  let accept_val = "application/json"
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

# DELETE /sites/{site_id}/forms/{form_id}
#
# operationId: deleteSiteForm
export def "delete-site-form" [
  site_id: string
  form_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($form_id | is-empty) { error make --unspanned { msg: "path parameter 'form_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), form_id: (encode-path-segment $form_id)} | format pattern "/sites/{site_id}/forms/{form_id}") $auth.query)
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

# GET /sites/{site_id}/metadata
#
# operationId: getSiteMetadata
export def "get-site-metadata" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/metadata") $auth.query)
  let accept_val = "application/json"
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

# PUT /sites/{site_id}/metadata
#
# operationId: updateSiteMetadata
export def "update-site-metadata" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/metadata") $auth.query)
  let req_body = $body
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

# This is an internal-only endpoint.
#
# GET /sites/{site_id}/plugin_runs/latest
# operationId: getLatestPluginRuns
export def "get-latest-plugin-runs" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --packages: list<string> # required
  --state: string
]: nothing -> oneof<table<package: string, reporting_event: string, state: string, summary: string, text: string, title: string, version: string, deploy_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($packages == null) { error make --unspanned { msg: "required query parameter 'packages' missing: pass --packages" } }
  let qp = [(serialize-qp "packages" $packages "csv") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/plugin_runs/latest") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"packages": $packages, "state": $state} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This is an internal-only endpoint.
#
# PUT /sites/{site_id}/plugins/{package}
# operationId: updatePlugin
export def "update-plugin" [
  site_id: string
  package: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pinned-version: string
]: any -> oneof<record<package: string, pinned_version: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($package | is-empty) { error make --unspanned { msg: "path parameter 'package' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), package: (encode-path-segment $package)} | format pattern "/sites/{site_id}/plugins/{package}") $auth.query)
  let req_body = {"pinned_version": $pinned_version} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# PUT /sites/{site_id}/rollback
#
# operationId: rollbackSiteDeploy
export def "rollback-site-deploy" [
  site_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/rollback") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# GET /sites/{site_id}/service-instances
#
# operationId: listServiceInstancesForSite
export def "list-service-instances-for-site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/service-instances") $auth.query)
  let accept_val = "application/json"
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

# POST /sites/{site_id}/services/{addon}/instances
#
# operationId: createServiceInstance
export def "create-service-instance" [
  site_id: string
  addon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($addon | is-empty) { error make --unspanned { msg: "path parameter 'addon' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), addon: (encode-path-segment $addon)} | format pattern "/sites/{site_id}/services/{addon}/instances") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# DELETE /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: deleteServiceInstance
export def "delete-service-instance" [
  site_id: string
  addon: string
  instance_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($addon | is-empty) { error make --unspanned { msg: "path parameter 'addon' must be non-empty" } }
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'instance_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), addon: (encode-path-segment $addon), instance_id: (encode-path-segment $instance_id)} | format pattern "/sites/{site_id}/services/{addon}/instances/{instance_id}") $auth.query)
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

# GET /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: showServiceInstance
export def "show-service-instance" [
  site_id: string
  addon: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($addon | is-empty) { error make --unspanned { msg: "path parameter 'addon' must be non-empty" } }
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'instance_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), addon: (encode-path-segment $addon), instance_id: (encode-path-segment $instance_id)} | format pattern "/sites/{site_id}/services/{addon}/instances/{instance_id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: updateServiceInstance
export def "update-service-instance" [
  site_id: string
  addon: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($addon | is-empty) { error make --unspanned { msg: "path parameter 'addon' must be non-empty" } }
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'instance_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), addon: (encode-path-segment $addon), instance_id: (encode-path-segment $instance_id)} | format pattern "/sites/{site_id}/services/{addon}/instances/{instance_id}") $auth.query)
  let req_body = $body
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

# GET /sites/{site_id}/snippets
#
# operationId: listSiteSnippets
export def "list-site-snippets" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/snippets") $auth.query)
  let accept_val = "application/json"
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

# POST /sites/{site_id}/snippets
#
# operationId: createSiteSnippet
export def "create-site-snippet" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --general: string
  --general-position: string
  --goal: string
  --goal-position: string
  --id: int # format: int32
  --body-site-id: string
  --title: string
]: any -> oneof<record<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/snippets") $auth.query)
  let req_body = {"general": $general, "general_position": $general_position, "goal": $goal, "goal_position": $goal_position, "id": $id, "site_id": $body_site_id, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# DELETE /sites/{site_id}/snippets/{snippet_id}
#
# operationId: deleteSiteSnippet
export def "delete-site-snippet" [
  site_id: string
  snippet_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($snippet_id | is-empty) { error make --unspanned { msg: "path parameter 'snippet_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), snippet_id: (encode-path-segment $snippet_id)} | format pattern "/sites/{site_id}/snippets/{snippet_id}") $auth.query)
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

# GET /sites/{site_id}/snippets/{snippet_id}
#
# operationId: getSiteSnippet
export def "get-site-snippet" [
  site_id: string
  snippet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($snippet_id | is-empty) { error make --unspanned { msg: "path parameter 'snippet_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), snippet_id: (encode-path-segment $snippet_id)} | format pattern "/sites/{site_id}/snippets/{snippet_id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /sites/{site_id}/snippets/{snippet_id}
#
# operationId: updateSiteSnippet
export def "update-site-snippet" [
  site_id: string
  snippet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --general: string
  --general-position: string
  --goal: string
  --goal-position: string
  --id: int # format: int32
  --body-site-id: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($snippet_id | is-empty) { error make --unspanned { msg: "path parameter 'snippet_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), snippet_id: (encode-path-segment $snippet_id)} | format pattern "/sites/{site_id}/snippets/{snippet_id}") $auth.query)
  let req_body = {"general": $general, "general_position": $general_position, "goal": $goal, "goal_position": $goal_position, "id": $id, "site_id": $body_site_id, "title": $title} | compact
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

# GET /sites/{site_id}/ssl
#
# operationId: showSiteTLSCertificate
export def "show-site-tls-certificate" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/ssl") $auth.query)
  let accept_val = "application/json"
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

# POST /sites/{site_id}/ssl
#
# operationId: provisionSiteTLSCertificate
export def "provision-site-tls-certificate" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate: string
  --key: string
  --ca-certificates: string
]: nothing -> oneof<record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "certificate" $certificate "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "ca_certificates" $ca_certificates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/ssl") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"certificate": $certificate, "key": $key, "ca_certificates": $ca_certificates} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# GET /sites/{site_id}/submissions
#
# operationId: listSiteSubmissions
export def "list-site-submissions" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/submissions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /sites/{site_id}/traffic_splits
#
# operationId: getSplitTests
export def "get-split-tests" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/traffic_splits") $auth.query)
  let accept_val = "application/json"
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

# POST /sites/{site_id}/traffic_splits
#
# operationId: createSplitTest
export def "create-split-test" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-tests: record
]: any -> oneof<record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/traffic_splits") $auth.query)
  let req_body = {"branch_tests": $branch_tests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# GET /sites/{site_id}/traffic_splits/{split_test_id}
#
# operationId: getSplitTest
export def "get-split-test" [
  site_id: string
  split_test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($split_test_id | is-empty) { error make --unspanned { msg: "path parameter 'split_test_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), split_test_id: (encode-path-segment $split_test_id)} | format pattern "/sites/{site_id}/traffic_splits/{split_test_id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /sites/{site_id}/traffic_splits/{split_test_id}
#
# operationId: updateSplitTest
export def "update-split-test" [
  site_id: string
  split_test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-tests: record
]: any -> oneof<record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($split_test_id | is-empty) { error make --unspanned { msg: "path parameter 'split_test_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), split_test_id: (encode-path-segment $split_test_id)} | format pattern "/sites/{site_id}/traffic_splits/{split_test_id}") $auth.query)
  let req_body = {"branch_tests": $branch_tests} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# POST /sites/{site_id}/traffic_splits/{split_test_id}/publish
#
# operationId: enableSplitTest
export def "enable-split-test" [
  site_id: string
  split_test_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($split_test_id | is-empty) { error make --unspanned { msg: "path parameter 'split_test_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), split_test_id: (encode-path-segment $split_test_id)} | format pattern "/sites/{site_id}/traffic_splits/{split_test_id}/publish") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# POST /sites/{site_id}/traffic_splits/{split_test_id}/unpublish
#
# operationId: disableSplitTest
export def "disable-split-test" [
  site_id: string
  split_test_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  if ($split_test_id | is-empty) { error make --unspanned { msg: "path parameter 'split_test_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), split_test_id: (encode-path-segment $split_test_id)} | format pattern "/sites/{site_id}/traffic_splits/{split_test_id}/unpublish") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# [Beta] Unlinks the repo from the site. This action will also: - Delete associated deploy keys - Delete outgoing webhooks for the repo - Delete the site's build hooks
#
# PUT /sites/{site_id}/unlink_repo
# operationId: unlinkSiteRepo
export def "unlink-site-repo" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'site_id' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/sites/{site_id}/unlink_repo") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# DELETE /submissions/{submission_id}
#
# operationId: deleteSubmission
export def "delete-submission" [
  submission_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($submission_id | is-empty) { error make --unspanned { msg: "path parameter 'submission_id' must be non-empty" } }
  let full_url = (build-url $base ({submission_id: (encode-path-segment $submission_id)} | format pattern "/submissions/{submission_id}") $auth.query)
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

# GET /submissions/{submission_id}
#
# operationId: listFormSubmission
export def "list-form-submission" [
  submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($submission_id | is-empty) { error make --unspanned { msg: "path parameter 'submission_id' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({submission_id: (encode-path-segment $submission_id)} | format pattern "/submissions/{submission_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /user
#
# operationId: getCurrentUser
export def "get-current-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<affiliate_id: string, avatar_url: string, created_at: string, email: string, full_name: string, id: string, last_login: string, login_providers: list<string>, onboarding_progress: record<slides: string>, site_count: int, uid: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user" $auth.query)
  let accept_val = "application/json"
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

# GET /{account_id}/builds/status
#
# operationId: getAccountBuildStatus
export def "get-account-build-status" [
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
]: nothing -> oneof<table<active: int, build_count: int, enqueued: int, minutes: record<current: int, current_average_sec: int, included_minutes: string, included_minutes_with_packs: string, last_updated_at: string, period_end_date: string, period_start_date: string, previous: int>, pending_concurrency: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/{account_id}/builds/status") $auth.query)
  let accept_val = "application/json"
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

# GET /{account_slug}/members
#
# operationId: listMembersForAccount
export def "list-members-for-account" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<avatar: string, email: string, full_name: string, id: string, role: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug)} | format pattern "/{account_slug}/members") $auth.query)
  let accept_val = "application/json"
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

# POST /{account_slug}/members
#
# operationId: addMemberToAccount
export def "add-member-to-account" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --role: string@role-completer
]: any -> oneof<table<avatar: string, email: string, full_name: string, id: string, role: string>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug)} | format pattern "/{account_slug}/members") $auth.query)
  let req_body = {"email": $email, "role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DELETE /{account_slug}/members/{member_id}
#
# operationId: removeAccountMember
export def "remove-account-member" [
  account_slug: string
  member_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'member_id' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug), member_id: (encode-path-segment $member_id)} | format pattern "/{account_slug}/members/{member_id}") $auth.query)
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

# GET /{account_slug}/members/{member_id}
#
# operationId: getAccountMember
export def "get-account-member" [
  account_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<avatar: string, email: string, full_name: string, id: string, role: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'member_id' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug), member_id: (encode-path-segment $member_id)} | format pattern "/{account_slug}/members/{member_id}") $auth.query)
  let accept_val = "application/json"
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

# PUT /{account_slug}/members/{member_id}
#
# operationId: updateAccountMember
export def "update-account-member" [
  account_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer
  --site-access: string@site-access-completer
  --site-ids: list<string>
]: any -> oneof<record<avatar: string, email: string, full_name: string, id: string, role: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'member_id' must be non-empty" } }
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug), member_id: (encode-path-segment $member_id)} | format pattern "/{account_slug}/members/{member_id}") $auth.query)
  let req_body = {"role": $role, "site_access": $site_access, "site_ids": $site_ids} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /{account_slug}/sites
# operationId: listSitesForAccount
export def "list-sites-for-account" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<table<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record, html: record, images: record, js: record, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list, id: string, locked: bool, name: string, published_at: string, required: list, required_functions: list, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug)} | format pattern "/{account_slug}/sites") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /{account_slug}/sites
# operationId: createSiteInTeam
export def "create-site-in-team" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configure-dns: oneof<nothing, bool>
  --account-name: string
  --body-account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list<string>
  --force-ssl: oneof<nothing, bool>
  --git-provider: string
  --id: string
  --id-domain: string
  --managed-dns: oneof<nothing, bool>
  --name: string
  --notification-email: string
  --password: string
  --plan: string
  --prerender: string
  --processing-settings: record # shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> oneof<record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_slug | is-empty) { error make --unspanned { msg: "path parameter 'account_slug' must be non-empty" } }
  let qp = [(serialize-qp "configure_dns" $configure_dns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_slug: (encode-path-segment $account_slug)} | format pattern "/{account_slug}/sites") $qp $auth.query)
  let req_body = {"account_name": $account_name, "account_slug": $body_account_slug, "admin_url": $admin_url, "build_image": $build_image, "build_settings": $build_settings, "capabilities": $capabilities, "created_at": $created_at, "custom_domain": $custom_domain, "default_hooks_data": $default_hooks_data, "deploy_hook": $deploy_hook, "deploy_url": $deploy_url, "domain_aliases": $domain_aliases, "force_ssl": $force_ssl, "git_provider": $git_provider, "id": $id, "id_domain": $id_domain, "managed_dns": $managed_dns, "name": $name, "notification_email": $notification_email, "password": $password, "plan": $plan, "prerender": $prerender, "processing_settings": $processing_settings, "published_deploy": $published_deploy, "screenshot_url": $screenshot_url, "session_id": $session_id, "ssl": $ssl, "ssl_url": $ssl_url, "state": $state, "updated_at": $updated_at, "url": $url, "user_id": $user_id, "repo": $repo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"configure_dns": $configure_dns} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}
