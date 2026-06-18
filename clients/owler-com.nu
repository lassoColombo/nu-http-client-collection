# Auto-generated client for Owler v1.0.0
# Source: https://api.apis.guru/v2/specs/owler.com/1.0.0/swagger.json
# Auth: --token flag or $env.OWLER_TOKEN

const BASE_URL = "https://api.owler.com"
const DEFAULT_AUTH = "user_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OWLER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "user_key" => { {headers: {user_key: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
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
  let full_url = (build-url $base "/v1/company/basicsearch" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v1/company/competitor/id/{company_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({website: (encode-path-segment $website)} | format pattern "/v1/company/competitor/url/{website}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let qp = [(serialize-qp "pagination_id" $pagination_id "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v1/company/competitorpremium/id/{company_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let qp = [(serialize-qp "pagination_id" $pagination_id "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({website: (encode-path-segment $website)} | format pattern "/v1/company/competitorpremium/url/{website}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base "/v1/company/fuzzysearch" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v1/company/id/{company_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base "/v1/company/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({website: (encode-path-segment $website)} | format pattern "/v1/company/url/{website}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v1/companypremium/id/{company_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({website: (encode-path-segment $website)} | format pattern "/v1/companypremium/url/{website}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base "/v1/feed" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base "/v1/feed/url" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
