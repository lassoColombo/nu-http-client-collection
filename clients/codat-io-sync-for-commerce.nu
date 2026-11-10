# Auto-generated client for Sync for Commerce API v1.1
# Source: https://api.apis.guru/v2/specs/codat.io/sync-for-commerce/1.1/openapi.json
# Auth: --token flag or $env.SYNC_FOR_COMMERCE_API_TOKEN

const BASE_URL = "https://api.codat.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SYNC_FOR_COMMERCE_API_TOKEN | default "" }
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
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.codat.io"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-visible-accounts" "request-sync" "get-configuration" "set-configuration" "list-integrations" "get-integration-branding" "get-sync-flow-url" "list-companies" "create-company" "list-connections" "create-connection" "update-connection" "request-sync-for-date-range" "get-sync-status" "update-visible-accounts-sync-flow" "get-config-text-sync-flow" "update-config-text-sync-flow" "commands"] | sort) } | get name | first)
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

# List visible accounts
#
# GET /clients/{clientId}/config/ui/accounts/platform/{platformKey}
# operationId: get-visible-accounts
export def "get-visible-accounts" [
  client_id: string
  platform_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<visibleAccounts: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  if ($platform_key | is-empty) { error make --unspanned { msg: "path parameter 'platformKey' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id), platform_key: (encode-path-segment $platform_key)} | format pattern "/clients/{client_id}/config/ui/accounts/platform/{platform_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Run a Commerce sync from the last successful sync
#
# POST /companies/{companyId}/sync/commerce/latest
# operationId: request-sync
export def "request-sync" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sync-to: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<commerceSyncId: string, companyId: string, dataConnections: table<additionalProperties: any, connectionInfo: record, created: string, dataConnectionErrors: list, id: string, integrationId: string, integrationKey: string, lastSync: string, linkUrl: string, platformName: string, sourceId: string, sourceType: string, status: string>, dataPushed: bool, errorMessage: string, syncDateRangeUtc: record<finish: string, start: string>, syncExceptionMessage: string, syncStatus: string, syncStatusCode: int, syncUtc: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/sync/commerce/latest") $auth.query)
  let req_body = {"syncTo": $sync_to} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Retrieve config preferences set for a company.
#
# GET /config/companies/{companyId}/sync/commerce
# operationId: get-configuration
export def "get-configuration" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<fees: record<accounts: record, feesSupplier: record<selectedSupplierId: string, supplierOptions: list>, syncFees: bool>, newPayments: record<accounts: record, syncPayments: bool>, payments: record<accounts: record, syncPayments: bool>, sales: record<accounts: record, grouping: record<groupingLevels: record, groupingPeriod: record>, invoiceStatus: record<invoiceStatusOptions: list, selectedInvoiceStatus: string>, newTaxRates: record<accountingTaxRateOptions: list, commerceTaxRateOptions: list, defaultZeroTaxRateOptions: list, selectedDefaultZeroTaxRateId: string, taxRateMappings: list>, salesCustomer: record<customerOptions: list, selectedCustomerId: string>, syncSales: bool, taxRates: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/config/companies/{company_id}/sync/commerce") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Create or update configuration.
#
# POST /config/companies/{companyId}/sync/commerce
# operationId: set-configuration
export def "set-configuration" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<fees: record<accounts: record, feesSupplier: record<selectedSupplierId: string, supplierOptions: list>, syncFees: bool>, newPayments: record<accounts: record, syncPayments: bool>, payments: record<accounts: record, syncPayments: bool>, sales: record<accounts: record, grouping: record<groupingLevels: record, groupingPeriod: record>, invoiceStatus: record<invoiceStatusOptions: list, selectedInvoiceStatus: string>, newTaxRates: record<accountingTaxRateOptions: list, commerceTaxRateOptions: list, defaultZeroTaxRateOptions: list, selectedDefaultZeroTaxRateId: string, taxRateMappings: list>, salesCustomer: record<customerOptions: list, selectedCustomerId: string>, syncSales: bool, taxRates: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/config/companies/{company_id}/sync/commerce") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List information on Codat's supported integrations
#
# GET /config/integrations
# operationId: list-integrations
export def "list-integrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<dataProvidedBy: string, datatypeFeatures: list, enabled: bool, integrationId: string, isBeta: bool, isOfflineConnector: bool, key: string, logoUrl: string, name: string, sourceId: string, sourceType: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/config/integrations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get branding for an integration
#
# GET /config/integrations/{platformKey}/branding
# operationId: get-integration-branding
export def "get-integration-branding" [
  platform_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<button: record<default: any, hover: any>, logo: record<full: record<image: record>, square: any>, sourceId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform_key | is-empty) { error make --unspanned { msg: "path parameter 'platformKey' must be non-empty" } }
  let full_url = (build-url $base ({platform_key: (encode-path-segment $platform_key)} | format pattern "/config/integrations/{platform_key}/branding") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Retrieve sync flow url
#
# GET /config/sync/commerce/{commerceKey}/{accountingKey}/start
# operationId: get-sync-flow-url
export def "get-sync-flow-url" [
  commerce_key: string
  accounting_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --merchant-identifier: string # Identifier for your merchant, can be the merchant name or Codat company id.
]: nothing -> oneof<record<url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($commerce_key | is-empty) { error make --unspanned { msg: "path parameter 'commerceKey' must be non-empty" } }
  if ($accounting_key | is-empty) { error make --unspanned { msg: "path parameter 'accountingKey' must be non-empty" } }
  let qp = [(serialize-qp "merchantIdentifier" $merchant_identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({commerce_key: (encode-path-segment $commerce_key), accounting_key: (encode-path-segment $accounting_key)} | format pattern "/config/sync/commerce/{commerce_key}/{accounting_key}/start") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"merchantIdentifier": $merchant_identifier} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List companies
#
# GET /meta/companies
# operationId: list-companies
export def "list-companies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<created: string, createdByUserName: string, dataConnections: list, description: string, id: string, lastSync: string, name: string, platform: string, redirect: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/meta/companies" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a sync for commerce company
#
# POST /meta/companies/sync
# operationId: create-company
export def "create-company" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the company in Codat with a partner-commerce data connection. (format: string)
]: any -> oneof<record<created: string, createdByUserName: string, dataConnections: table<additionalProperties: any, connectionInfo: record, created: string, dataConnectionErrors: list, id: string, integrationId: string, integrationKey: string, lastSync: string, linkUrl: string, platformName: string, sourceId: string, sourceType: string, status: string>, description: string, id: string, lastSync: string, name: string, platform: string, redirect: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meta/companies/sync" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List data connections
#
# GET /meta/companies/{companyId}/connections
# operationId: list-connections
export def "list-connections" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<additionalProperties: any, connectionInfo: record, created: string, dataConnectionErrors: list, id: string, integrationId: string, integrationKey: string, lastSync: string, linkUrl: string, platformName: string, sourceId: string, sourceType: string, status: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/meta/companies/{company_id}/connections") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a data connection
#
# POST /meta/companies/{companyId}/connections
# operationId: create-connection
export def "create-connection" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> oneof<record<additionalProperties: any, connectionInfo: record, created: string, dataConnectionErrors: table<errorMessage: string, erroredOnUtc: string, statusCode: string, statusText: string>, id: string, integrationId: string, integrationKey: string, lastSync: string, linkUrl: string, platformName: string, sourceId: string, sourceType: string, status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/meta/companies/{company_id}/connections") $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update data connection
#
# PATCH /meta/companies/{companyId}/connections/{connectionId}
# operationId: update-connection
export def "update-connection" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # The current authorization status of the data connection. (nullable)
]: any -> oneof<record<additionalProperties: any, connectionInfo: record, created: string, dataConnectionErrors: table<errorMessage: string, erroredOnUtc: string, statusCode: string, statusText: string>, id: string, integrationId: string, integrationKey: string, lastSync: string, linkUrl: string, platformName: string, sourceId: string, sourceType: string, status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/meta/companies/{company_id}/connections/{connection_id}") $auth.query)
  let req_body = {"status": $status} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Run a Commerce sync from a given date range
#
# POST /meta/companies/{companyId}/sync/commerce/historic
# operationId: request-sync-for-date-range
export def "request-sync-for-date-range" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --finish: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --start: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<commerceSyncId: string, companyId: string, dataConnections: table<additionalProperties: any, connectionInfo: record, created: string, dataConnectionErrors: list, id: string, integrationId: string, integrationKey: string, lastSync: string, linkUrl: string, platformName: string, sourceId: string, sourceType: string, status: string>, dataPushed: bool, errorMessage: string, syncDateRangeUtc: record<finish: string, start: string>, syncExceptionMessage: string, syncStatus: string, syncStatusCode: int, syncUtc: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/meta/companies/{company_id}/sync/commerce/historic") $auth.query)
  let req_body = {"finish": $finish, "start": $start} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get status for a company's syncs
#
# GET /meta/companies/{companyId}/sync/commerce/status
# operationId: get-sync-status
export def "get-sync-status" [
  company_id: string
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/meta/companies/{company_id}/sync/commerce/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update the visible accounts on Sync Flow
#
# PATCH /sync/commerce/config/ui/accounts/platform/{commerceKey}
# operationId: update-visible-accounts-sync-flow
export def "update-visible-accounts-sync-flow" [
  commerce_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --visible-accounts: list<string> # Visible accounts on sync flow. (nullable)
]: any -> oneof<record<visibleAccounts: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($commerce_key | is-empty) { error make --unspanned { msg: "path parameter 'commerceKey' must be non-empty" } }
  let full_url = (build-url $base ({commerce_key: (encode-path-segment $commerce_key)} | format pattern "/sync/commerce/config/ui/accounts/platform/{commerce_key}") $auth.query)
  let req_body = {"visibleAccounts": $visible_accounts} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Retrieve preferences for text fields on Sync Flow
#
# GET /sync/commerce/config/ui/text
# operationId: get-config-text-sync-flow
export def "get-config-text-sync-flow" [
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
  let full_url = (build-url $base "/sync/commerce/config/ui/text" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Update preferences for text fields on sync flow
#
# PATCH /sync/commerce/config/ui/text
# operationId: update-config-text-sync-flow
export def "update-config-text-sync-flow" [
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
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/commerce/config/ui/text" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
