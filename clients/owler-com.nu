# Auto-generated client for Owler v1.0.0
# Source: https://api.apis.guru/v2/specs/owler.com/1.0.0/swagger.json
# Auth: --token flag or $env.OWLER_TOKEN

const BASE_URL = "https://api.owler.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o OWLER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "user_key" => { {scheme: $scheme, headers: {user_key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.owler.com"] }
def auth-scheme-completer [] { ["user_key"] }

# Completers for enum parameters
def format-completer [] { ["json" "xml"] }
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "company-basicsearch list-basic" } } | get name | first)
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

# Basic Search Company by Ticker or Website or Name or PermID
#
# GET /v1/company/basicsearch
# operationId: basicCompanySearch
export def "company-basicsearch list-basic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --q: string # Search term
  --fields: list<string> # Fields to be searched - name, website, ticker, permid. If not specfied, will be searched against all fields
  --limit: string # Number of results to be displayed - 10 (by default, if not specified) to 30
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<company: table<company_id: int, hq_address: record, name: string, perm_id: string, profile_url: string, short_name: string, website: string>> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/company/basicsearch" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "fields": $fields, "limit": $limit, "format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Competitor information by Id
#
# GET /v1/company/competitor/id/{companyId}
export def "company-competitor-id get" [
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
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<competitor: table<company_id: int, logo_url: string, name: string, profile_url: string, short_name: string, website: string>> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v1/company/competitor/id/{company_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Competitor information by URL
#
# GET /v1/company/competitor/url/{website}
export def "company-competitor-url get" [
  website: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<competitor: table<company_id: int, logo_url: string, name: string, profile_url: string, short_name: string, website: string>> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($website | is-empty) { error make --unspanned { msg: "path parameter 'website' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({website: (encode-path-segment $website)} | format pattern "/v1/company/competitor/url/{website}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Competitor information by Id
#
# GET /v1/company/competitorpremium/id/{companyId}
export def "company-competitorpremium-id get" [
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
  --accept: string@accept-completer # Response content type
  --pagination-id: string # Pass pagination_id as * in the first API request. The API response will return top competitors along with the next pagination_id which can be passed in the subsequent API request to get the next set of competitors. Repeat this process until needed or till the pagination_id returned is blank. Note:Every response will have maximum of 50 competitors.
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<competitor: table<company_id: int, logo_url: string, name: string, profile_url: string, score: int, short_name: string, website: string>, pagination_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "pagination_id" $pagination_id "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v1/company/competitorpremium/id/{company_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pagination_id": $pagination_id, "format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Competitor information by Url
#
# GET /v1/company/competitorpremium/url/{website}
export def "company-competitorpremium-url get" [
  website: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pagination-id: string # Pass pagination_id as * in the first API request. The API response will return top competitors along with the next pagination_id which can be passed in the subsequent API request to get the next set of competitors. Repeat this process until needed or till the pagination_id returned is blank. Note:Every response will have maximum of 50 competitors.
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<competitor: table<company_id: int, logo_url: string, name: string, profile_url: string, score: int, short_name: string, website: string>, pagination_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($website | is-empty) { error make --unspanned { msg: "path parameter 'website' must be non-empty" } }
  let qp = [(serialize-qp "pagination_id" $pagination_id "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({website: (encode-path-segment $website)} | format pattern "/v1/company/competitorpremium/url/{website}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pagination_id": $pagination_id, "format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fuzzy Search Company by Name or Address or Phone
#
# GET /v1/company/fuzzysearch
# operationId: fuzzyCompanySearch
export def "company-fuzzysearch list-fuzzy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --q: string # Search term
  --fields: list<string> # Fields to be searched - name, website, ticker, permid, address, phone. Each field and its corresponding value has to be specified
  --limit: string # Number of results to be displayed - 10 (by default, if not specified) to 30
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/company/fuzzysearch" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "fields": $fields, "limit": $limit, "format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Company by Id
#
# GET /v1/company/id/{companyId}
export def "company-id get" [
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
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<acquisition: table<acquirer_company_id: string, amount: string, company_id: string, date: string, name: string, status: string, undisclosed: string, website: string>, ceo: record<ceo_rating: string, first_name: string, image_url: string, last_name: string>, company_id: int, company_type: string, description: string, employee_count: string, facebook_link: string, founded_date: string, funding: table<amount: string, date: string, investor: list, type: string, undisclosed: string>, hq_address: record<city: string, country: string, phone: string, postal_code: string, state: string, street1: string, street2: string>, industries: list<string>, linkedin_link: string, logo_url: string, name: string, perm_id: string, portfolio_company_ids: list<int>, profile_url: string, revenue: string, sectors: table<name: string, parent_industry: string>, short_name: string, stock: record<exchange: string, ticker: string>, twitter_link: string, website: string, youtube_link: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v1/company/id/{company_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search Company by Ticker or Website or Name or PermID
#
# GET /v1/company/search
# operationId: searchCompany
export def "company-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --q: string # Search term
  --fields: list<string> # Fields to be searched - name, website, ticker. If not specified, will be searched against all fields
  --limit: string # Number of results to be displayed - 10 (by default, if not specified) to 30
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<feeds: table<category: string, company: record, enclosure_image: string, feed_date: string, id: string, owler_feed_url: string, publisher_logo: string, publisher_name: string, source_url: string, title: string>, pagination_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/company/search" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "fields": $fields, "limit": $limit, "format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Company by URL
#
# GET /v1/company/url/{website}
export def "company-url get" [
  website: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<acquisition: table<acquirer_company_id: string, amount: string, company_id: string, date: string, name: string, status: string, undisclosed: string, website: string>, ceo: record<ceo_rating: string, first_name: string, image_url: string, last_name: string>, company_id: int, company_type: string, description: string, employee_count: string, facebook_link: string, founded_date: string, funding: table<amount: string, date: string, investor: list, type: string, undisclosed: string>, hq_address: record<city: string, country: string, phone: string, postal_code: string, state: string, street1: string, street2: string>, industries: list<string>, linkedin_link: string, logo_url: string, name: string, perm_id: string, portfolio_company_ids: list<int>, profile_url: string, revenue: string, sectors: table<name: string, parent_industry: string>, short_name: string, stock: record<exchange: string, ticker: string>, twitter_link: string, website: string, youtube_link: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($website | is-empty) { error make --unspanned { msg: "path parameter 'website' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({website: (encode-path-segment $website)} | format pattern "/v1/company/url/{website}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Complete Company Info by Id
#
# GET /v1/companypremium/id/{companyId}
export def "companypremium-id get" [
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
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<acquisition: table<acquirer_company_id: string, amount: string, company_id: string, date: string, name: string, status: string, undisclosed: string, website: string>, ceo: record<ceo_rating: string, first_name: string, image_url: string, last_name: string>, company_id: int, company_type: string, description: string, employee_count: string, facebook_link: string, founded_date: string, funding: table<amount: string, date: string, investor: list, type: string, undisclosed: string>, hq_address: record<city: string, country: string, phone: string, postal_code: string, state: string, street1: string, street2: string>, industries: list<string>, linkedin_link: string, logo_url: string, name: string, perm_id: string, portfolio_company_ids: list<int>, profile_url: string, revenue: string, sectors: table<name: string, parent_industry: string>, short_name: string, stock: record<exchange: string, ticker: string>, twitter_link: string, website: string, youtube_link: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v1/companypremium/id/{company_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Basic Company Info by Url
#
# GET /v1/companypremium/url/{website}
export def "companypremium-url get" [
  website: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
]: nothing -> record<acquisition: table<acquirer_company_id: string, amount: string, company_id: string, date: string, name: string, status: string, undisclosed: string, website: string>, ceo: record<ceo_rating: string, first_name: string, image_url: string, last_name: string>, company_id: int, company_type: string, description: string, employee_count: string, facebook_link: string, founded_date: string, funding: table<amount: string, date: string, investor: list, type: string, undisclosed: string>, hq_address: record<city: string, country: string, phone: string, postal_code: string, state: string, street1: string, street2: string>, industries: list<string>, linkedin_link: string, logo_url: string, name: string, perm_id: string, portfolio_company_ids: list<int>, profile_url: string, revenue: string, sectors: table<name: string, parent_industry: string>, short_name: string, stock: record<exchange: string, ticker: string>, twitter_link: string, website: string, youtube_link: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($website | is-empty) { error make --unspanned { msg: "path parameter 'website' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({website: (encode-path-segment $website)} | format pattern "/v1/companypremium/url/{website}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Feeds for given Company Ids
#
# GET /v1/feed
export def "feed get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
  --company-id: list<string> # Company Ids separated by comma (Maximum of 150 Company Ids)
  --limit: string # Number of results to be displayed - 10 (by default, if not specified) to 100 (default: 10)
  --pagination-id: string # Pass pagination_id as blank in the first API request. The API response will return the latest feeds along with the next pagination_id which can be passed in the subsequent API request to get the next set of feeds. Repeat this process until needed or till the pagination_id returned is blank (default: *)
  --category: list<string> # Categories separated by comma. If not specified, will search against all categories
]: nothing -> record<feeds: table<category: string, company: record, enclosure_image: string, feed_date: string, id: string, owler_feed_url: string, publisher_logo: string, publisher_name: string, source_url: string, title: string>, pagination_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "company_id" $company_id "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "pagination_id" $pagination_id "scalar") (serialize-qp "category" $category "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/feed" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "company_id": $company_id, "limit": $limit, "pagination_id": $pagination_id, "category": $category} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Feeds for given Company Websites
#
# GET /v1/feed/url
export def "feed-url get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # Format of the response content - json (by default if not specified), xml (default: json)
  --domain: list<string> # Company Websites separated by comma (Maximum of 10 Company Websites)
  --limit: string # Number of results to be displayed - 10 (by default, if not specified) to 100 (default: 10)
  --pagination-id: string # Pass pagination_id as blank in the first API request. The API response will return the latest feeds along with the next pagination_id which can be passed in the subsequent API request to get the next set of feeds. Repeat this process until needed or till the pagination_id returned is blank (default: *)
  --category: list<string> # Categories separated by comma. If not specified, will search against all categories
]: nothing -> record<feeds: table<category: string, company: record, enclosure_image: string, feed_date: string, id: string, owler_feed_url: string, publisher_logo: string, publisher_name: string, source_url: string, title: string>, pagination_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "domain" $domain "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "pagination_id" $pagination_id "scalar") (serialize-qp "category" $category "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/feed/url" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "domain": $domain, "limit": $limit, "pagination_id": $pagination_id, "category": $category} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
