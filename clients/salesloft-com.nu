# Auto-generated client for SalesLoft Platform vv2
# Source: https://api.apis.guru/v2/specs/salesloft.com/v2/openapi.json
# Auth: --token flag or $env.SALESLOFT_PLATFORM_TOKEN

const BASE_URL = "https://api.salesloft.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SALESLOFT_PLATFORM_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.salesloft.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-stages-json get" } } | get name | first)
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

# List account stages
#
# GET /v2/account_stages.json
export def "account-stages-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of account stages to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, order. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/account_stages.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "updated_at": $updated_at, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch an account stage
#
# GET /v2/account_stages/{id}.json
export def "account-stages get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/account_stages/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Account Tiers
#
# GET /v2/account_tiers.json
export def "account-tiers-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of Account Tiers to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --name: list<string> # Filters Account Tiers by name. Multiple names can be applied
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, order. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "name" $name "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/account_tiers.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "name": $name, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch an account tier
#
# GET /v2/account_tiers/{id}.json
export def "account-tiers get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/account_tiers/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upsert an account
#
# POST /v2/account_upserts.json
export def "account-upserts-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-tier-id: int # ID of the Account Tier for this Account
  --city: string # City
  --company-stage-id: int # ID of the CompanyStage assigned to this Account
  --company-type: string # Type of the Account's company
  --conversational-name: string # Conversational name of the Account
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either an Account (001) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "account:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: list # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --description: string # Description
  --do-not-contact: oneof<nothing, bool> # Whether this company can not be contacted. Values are either true or false. Setting this to true will remove all associated people from all active communications
  domain: string # Website domain, not a fully qualified URI
  --founded: string # Date or year of founding
  --id: int # ID of the account to update. Used if the upsert_key=id. When id and another upsert_key are provided, the request will fail if the upsert record id and id parameter don't match.
  --industry: string # Industry
  --linkedin-url: string # Full LinkedIn url
  --locale: string # Time locale
  name: string # Account Full Name
  --owner-id: int # ID of the User that owns this Account
  --phone: string # Phone number without formatting
  --postal-code: string # Postal code
  --revenue-range: string # Estimated revenue range
  --size: string # Estimated number of people in employment
  --state: string # State
  --street: string # Street name and number
  --tags: list<string> # All tags applied to this Account
  --twitter-handle: string # Twitter handle, with @
  --upsert-key: string # Name of the parameter to upsert on. The field must be provided in the input parameters, or the request will fail. The request will also fail if there are multiple records matched by the upsert field. If upsert_key is not provided, this endpoint will not update an existing record. Valid options are: id, crm_id, domain. If crm_id is provided, then a valid crm_id_type must be provided, as documented for the account create and update endpoints.
  --website: string # Website
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/account_upserts.json")
  let req_body = {"account_tier_id": $account_tier_id, "city": $city, "company_stage_id": $company_stage_id, "company_type": $company_type, "conversational_name": $conversational_name, "country": $country, "crm_id": $crm_id, "crm_id_type": $crm_id_type, "custom_fields": $custom_fields, "description": $description, "do_not_contact": $do_not_contact, "domain": $domain, "founded": $founded, "id": $id, "industry": $industry, "linkedin_url": $linkedin_url, "locale": $locale, "name": $name, "owner_id": $owner_id, "phone": $phone, "postal_code": $postal_code, "revenue_range": $revenue_range, "size": $size, "state": $state, "street": $street, "tags": $tags, "twitter_handle": $twitter_handle, "upsert_key": $upsert_key, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List accounts
#
# GET /v2/accounts.json
export def "accounts-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of accounts to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --crm-id: list<string> # Filters accounts by crm_id. Multiple crm ids can be applied
  --tag: list<string> # Filters accounts by the tags applied to the account. Multiple tags can be applied
  --tag-id: list<int> # Filters accounts by the tag id's applied to the account. Multiple tag id's can be applied
  --created-at: list<string> # Equality filters that are applied to the created_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --domain: string # Domain of the accounts to fetch. Domains are unique and lowercase
  --website: list<string> # Filters accounts by website. Multiple websites can be applied. An additional value of "_is_null" can be passed to filter accounts that do not have a website.
  --archived: oneof<nothing, bool> # Filters accounts by archived_at status. Returns only accounts where archived_at is not null if this field is true. Returns only accounts where archived_at is null if this field is false. Do not pass this parameter to return both archived and unarchived accounts. This filter is not applied if any value other than "true" or "false" is passed.
  --name: list<string> # Names of accounts to fetch. Name matches are exact and case sensitive. Multiple names can be fetched.
  --account-stage-id: list<int> # Filters accounts by account_stage_id. Multiple account_stage_ids can be applied. An additional value of "_is_null" can be passed to filter accounts that do not have account_stage_id
  --account-tier-id: list<int> # Filters accounts by account_tier_id. Multiple account tier ids can be applied
  --owner-id: list<string> # Filters accounts by owner_id. Multiple owner_ids can be applied. An additional value of "_is_null" can be passed to filter accounts that are unowned
  --owner-is-active: oneof<nothing, bool> # Filters accounts by whether the owner is active or not.
  --last-contacted: record # Equality filters that are applied to the last_contacted field. A single filter can be used by itself or combined with other filters to create a range. Additional values of "_is_null" or "_is_not_null" can be passed to filter records that either have no timestamp value or any timestamp value. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --custom-fields: record # Filters by accounts matching all given custom fields. The custom field names are case-sensitive, but the provided values are case-insensitive. Example: v2/accounts?custom_fields[custom_field_name]=custom_field_value
  --industry: list<string> # Filters accounts by industry by exact match. Supports partial matching
  --country: list<string> # Filters accounts by country by exact match. Supports partial matching
  --state: list<string> # Filters accounts by state by exact match. Supports partial matching
  --city: list<string> # Filters accounts by city by exact match. Supports partial matching
  --owner-crm-id: list<string> # Filters accounts by owner_crm_id. Multiple owner_crm_ids can be applied. An additional value of "_is_null" can be passed to filter accounts that are unowned. A "_not_in" modifier can be used to exclude specific owner_crm_ids. Example: v2/accounts?owner_crm_id[_not_in]=id
  --locales: list<string> # Filters accounts by locale. Multiple locales are allowed
  --user-relationships: record # Filters by accounts matching all given user relationship fields, _is_null or _unmapped can be passed to filter accounts with null or unmapped user relationship values. Example: v2/accounts?user_relationships[name]=value
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, last_contacted_at, account_stage, account_stage_name, account_tier, account_tier_name, name, counts_people. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "crm_id" $crm_id "csv") (serialize-qp "tag" $tag "csv") (serialize-qp "tag_id" $tag_id "csv") (serialize-qp "created_at" $created_at "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "domain" $domain "scalar") (serialize-qp "website" $website "csv") (serialize-qp "archived" $archived "scalar") (serialize-qp "name" $name "csv") (serialize-qp "account_stage_id" $account_stage_id "csv") (serialize-qp "account_tier_id" $account_tier_id "csv") (serialize-qp "owner_id" $owner_id "csv") (serialize-qp "owner_is_active" $owner_is_active "scalar") (serialize-qp "last_contacted" $last_contacted "multi") (serialize-qp "custom_fields" $custom_fields "multi") (serialize-qp "industry" $industry "csv") (serialize-qp "country" $country "csv") (serialize-qp "state" $state "csv") (serialize-qp "city" $city "csv") (serialize-qp "owner_crm_id" $owner_crm_id "csv") (serialize-qp "locales" $locales "csv") (serialize-qp "user_relationships" $user_relationships "multi") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/accounts.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "crm_id": $crm_id, "tag": $tag, "tag_id": $tag_id, "created_at": $created_at, "updated_at": $updated_at, "domain": $domain, "website": $website, "archived": $archived, "name": $name, "account_stage_id": $account_stage_id, "account_tier_id": $account_tier_id, "owner_id": $owner_id, "owner_is_active": $owner_is_active, "last_contacted": $last_contacted, "custom_fields": $custom_fields, "industry": $industry, "country": $country, "state": $state, "city": $city, "owner_crm_id": $owner_crm_id, "locales": $locales, "user_relationships": $user_relationships, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create an account
#
# POST /v2/accounts.json
export def "accounts-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-tier-id: int # ID of the Account Tier for this Account
  --city: string # City
  --company-stage-id: int # ID of the CompanyStage assigned to this Account
  --company-type: string # Type of the Account's company
  --conversational-name: string # Conversational name of the Account
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either an Account (001) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "account:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: list # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --description: string # Description
  --do-not-contact: oneof<nothing, bool> # Whether this company can not be contacted. Values are either true or false. Setting this to true will remove all associated people from all active communications
  domain: string # Website domain, not a fully qualified URI
  --founded: string # Date or year of founding
  --industry: string # Industry
  --linkedin-url: string # Full LinkedIn url
  --locale: string # Time locale
  name: string # Account Full Name
  --owner-id: int # ID of the User that owns this Account
  --phone: string # Phone number without formatting
  --postal-code: string # Postal code
  --revenue-range: string # Estimated revenue range
  --size: string # Estimated number of people in employment
  --state: string # State
  --street: string # Street name and number
  --tags: list<string> # All tags applied to this Account
  --twitter-handle: string # Twitter handle, with @
  --website: string # Website
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/accounts.json")
  let req_body = {"account_tier_id": $account_tier_id, "city": $city, "company_stage_id": $company_stage_id, "company_type": $company_type, "conversational_name": $conversational_name, "country": $country, "crm_id": $crm_id, "crm_id_type": $crm_id_type, "custom_fields": $custom_fields, "description": $description, "do_not_contact": $do_not_contact, "domain": $domain, "founded": $founded, "industry": $industry, "linkedin_url": $linkedin_url, "locale": $locale, "name": $name, "owner_id": $owner_id, "phone": $phone, "postal_code": $postal_code, "revenue_range": $revenue_range, "size": $size, "state": $state, "street": $street, "tags": $tags, "twitter_handle": $twitter_handle, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete an account
#
# DELETE /v2/accounts/{id}.json
export def "accounts delete" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/accounts/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch an account
#
# GET /v2/accounts/{id}.json
export def "accounts get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/accounts/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an existing Account
#
# PUT /v2/accounts/{id}.json
export def "accounts update" [
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
  --account-tier-id: int # ID of the Account Tier for this Account
  --archived: oneof<nothing, bool> # Whether this Account should be archived or not. Setting this to true sets archived_at to the current time if it's not already set. Setting this to false will set archived_at to null
  --city: string # City
  --company-stage-id: int # ID of the CompanyStage assigned to this Account
  --company-type: string # Type of the Account's company
  --conversational-name: string # Conversational name of the Account
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either an Account (001) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "account:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: list # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --description: string # Description
  --do-not-contact: oneof<nothing, bool> # Whether this company can not be contacted. Values are either true or false. Setting this to true will remove all associated people from all active communications
  domain: string # Website domain, not a fully qualified URI
  --founded: string # Date or year of founding
  --industry: string # Industry
  --linkedin-url: string # Full LinkedIn url
  --locale: string # Time locale
  name: string # Account Full Name
  --owner-id: int # ID of the User that owns this Account
  --phone: string # Phone number without formatting
  --postal-code: string # Postal code
  --revenue-range: string # Estimated revenue range
  --size: string # Estimated number of people in employment
  --state: string # State
  --street: string # Street name and number
  --tags: list<string> # All tags applied to this Account
  --twitter-handle: string # Twitter handle, with @
  --website: string # Website
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/accounts/{id}.json"))
  let req_body = {"account_tier_id": $account_tier_id, "archived": $archived, "city": $city, "company_stage_id": $company_stage_id, "company_type": $company_type, "conversational_name": $conversational_name, "country": $country, "crm_id": $crm_id, "crm_id_type": $crm_id_type, "custom_fields": $custom_fields, "description": $description, "do_not_contact": $do_not_contact, "domain": $domain, "founded": $founded, "industry": $industry, "linkedin_url": $linkedin_url, "locale": $locale, "name": $name, "owner_id": $owner_id, "phone": $phone, "postal_code": $postal_code, "revenue_range": $revenue_range, "size": $size, "state": $state, "street": $street, "tags": $tags, "twitter_handle": $twitter_handle, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List call instructions
#
# GET /v2/action_details/call_instructions.json
export def "action-details-call-instructions-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of call instructions to fetch.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/action_details/call_instructions.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch a call instructions
#
# GET /v2/action_details/call_instructions/{id}.json
export def "action-details-call-instructions get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/action_details/call_instructions/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List actions
#
# GET /v2/actions.json
export def "actions-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of actions to fetch.
  --step-id: int # Fetch actions by step ID
  --type: string # Filter actions by type
  --due-on: list<string> # Equality filters that are applied to the due_on field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --user-guid: list<string> # Filters actions by the user's guid. Multiple user guids can be applied. The user must be a team admin to filter other users' actions
  --person-id: list<int> # Filters actions by person_id. Multiple person ids can be applied
  --cadence-id: list<int> # Filters actions by cadence_id. Multiple cadence ids can be applied
  --multitouch-group-id: list<int> # Filters actions by multitouch_group_id. Multiple multitouch group ids can be applied
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "step_id" $step_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "due_on" $due_on "csv") (serialize-qp "user_guid" $user_guid "csv") (serialize-qp "person_id" $person_id "csv") (serialize-qp "cadence_id" $cadence_id "csv") (serialize-qp "multitouch_group_id" $multitouch_group_id "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/actions.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "step_id": $step_id, "type": $type, "due_on": $due_on, "user_guid": $user_guid, "person_id": $person_id, "cadence_id": $cadence_id, "multitouch_group_id": $multitouch_group_id, "updated_at": $updated_at, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch an action
#
# GET /v2/actions/{id}.json
export def "actions get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/actions/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an activity
#
# POST /v2/activities.json
export def "activities-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-id: int # Action that is being completed. This will validate that the action is still valid before completed it. The same action can never be successfully passed twice to this endpoint. The action must have a type of 'integration'.
  --task-id: int # Task that is being completed. This will validate that the task is still valid before completed it. The same action can never be successfully passed twice to this endpoint. The task must have a type of 'integration'.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/activities.json")
  let req_body = {"action_id": $action_id, "task_id": $task_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List calls
#
# GET /v2/activities/calls.json
export def "activities-calls-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of calls to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --created-at: list<string> # Equality filters that are applied to the created_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --user-guid: list<string> # Filters list to only include guids
  --person-id: list<int> # Filters calls by person_id. Multiple person ids can be applied
  --sentiment: list<string> # Filters calls by sentiment. Sentiment matches are exact and case sensitive. Multiple sentiments are allowed.
  --disposition: list<string> # Filters calls by disposition. Disposition matches are exact and case sensitive. Multiple dispositions are allowed.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "created_at" $created_at "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "user_guid" $user_guid "csv") (serialize-qp "person_id" $person_id "csv") (serialize-qp "sentiment" $sentiment "csv") (serialize-qp "disposition" $disposition "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/activities/calls.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "created_at": $created_at, "updated_at": $updated_at, "user_guid": $user_guid, "person_id": $person_id, "sentiment": $sentiment, "disposition": $disposition, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create a call
#
# POST /v2/activities/calls.json
export def "activities-calls-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-id: int # Action that this call is being logged for. This will validate that the action is still valid before completing it. The same action can never be successfully passed twice to this endpoint. The action must have a type of 'phone'.
  --crm-params: record # CRM specific parameters. Some parameters are required on a per-team basis. Consume the CrmActivityFields endpoint to receive a list of valid parameters. The "field" property is passed as the key of this object, and the value of this object is the value that you would like to set. If CrmActivityField has a non-null value, then that value must be submitted, or excluded from API calls, as these values are automatically applied.
  --disposition: string # The disposition of the call. Can be required on a per-team basis. Must be present in the disposition list.
  --duration: int # The length of the call, in seconds
  --linked-call-data-record-ids: list<int> # CallDataRecord associations that will become linked to the created call. It is possible to pass multiple CallDataRecord ids in this field; this can be used to represent multiple phone calls that made up a single call. Any call data record that is used must not already be linked to a call. It is not possible to link a call data record to multiple calls, and it is not possible to re-assign a call data record to a different call.
  --notes: string # Notes to log for the call. This is similar to the notes endpoint, but ensures that the notes get synced to the user's CRM
  person_id: int # The ID of the person whom this call will be logged for
  --sentiment: string # The sentiment of the call. Can be required on a per-team basis. Must be present in the sentiment list.
  --body-to: string # The phone number that was called
  --user-guid: string # Guid of the user whom this call should be logged for. Defaults to the authenticated user. Only team admins can pass another user's guid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/activities/calls.json")
  let req_body = {"action_id": $action_id, "crm_params": $crm_params, "disposition": $disposition, "duration": $duration, "linked_call_data_record_ids": $linked_call_data_record_ids, "notes": $notes, "person_id": $person_id, "sentiment": $sentiment, "to": $body_to, "user_guid": $user_guid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch a call
#
# GET /v2/activities/calls/{id}.json
export def "activities-calls get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/activities/calls/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List emails
#
# GET /v2/activities/emails.json
export def "activities-emails-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of emails to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --bounced: oneof<nothing, bool> # Filters emails by whether they have bounced or not
  --crm-activity-id: list<int> # Filters emails by crm_activity_id. Multiple crm activty ids can be applied
  --action-id: list<int> # Filters emails by action_id. Multiple action ids can be applied
  --user-id: list<int> # Filters emails by user_id. Multiple User ids can be applied
  --status: list<string> # Filters emails by status. Multiple status can be applied, possible values are sent, sent_from_gmail, sent_from_external, pending, pending_reply_check, scheduled, sending, delivering, failed, cancelled, pending_through_gmail, pending_through_external
  --cadence-id: list<int> # Filters emails by cadence. Multiple cadence ids can be applied
  --step-id: list<int> # Filters emails by step. Multiple step ids can be applied
  --one-off: oneof<nothing, bool> # Filters emails by one-off only
  --scoped-fields: list<string> # Specify explicit scoped fields desired on the Email Resource.
  --person-id: list<int> # Filters emails by person_id. Multiple person ids can be applied
  --email-addresses: list<string> # Filters emails by recipient email address. Multiple emails can be applied.
  --personalization: list<string> # Filters emails by personalization score
  --sent-at: list<string> # Equality filters that are applied to the sent_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: updated_at, send_time. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "bounced" $bounced "scalar") (serialize-qp "crm_activity_id" $crm_activity_id "csv") (serialize-qp "action_id" $action_id "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "status" $status "csv") (serialize-qp "cadence_id" $cadence_id "csv") (serialize-qp "step_id" $step_id "csv") (serialize-qp "one_off" $one_off "scalar") (serialize-qp "scoped_fields" $scoped_fields "csv") (serialize-qp "person_id" $person_id "csv") (serialize-qp "email_addresses" $email_addresses "csv") (serialize-qp "personalization" $personalization "csv") (serialize-qp "sent_at" $sent_at "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/activities/emails.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "updated_at": $updated_at, "bounced": $bounced, "crm_activity_id": $crm_activity_id, "action_id": $action_id, "user_id": $user_id, "status": $status, "cadence_id": $cadence_id, "step_id": $step_id, "one_off": $one_off, "scoped_fields": $scoped_fields, "person_id": $person_id, "email_addresses": $email_addresses, "personalization": $personalization, "sent_at": $sent_at, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch an email
#
# GET /v2/activities/emails/{id}.json
export def "activities-emails get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/activities/emails/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Past Activities
#
# GET /v2/activity_histories
export def "activity-histories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --sort-by: string # Key to sort on, must be one of: occurred_at, updated_at. Defaults to occurred_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --type: string # Filter by the type of activity. Must be one of: added_to_cadence, completed_action, call, requested_email, sent_email, received_email, email_reply, note, success, dnc_event, residency_change, meeting, meeting_held, message_conversation, task, voicemail, opportunity_stage_change, opportunity_amount_change, opportunity_close_date_change. Can be provided as an array, or as an object of type[resource_type][]=type
  --resource: string # For internal use only. This field does not comply with our backwards compatibility policies. This filter is for authenticated users of Salesloft only and will not work for OAuth Applications. Filter by the {resource_type, resource_id} of activity. Provide this in the format resource[]=person,1234
  --occurred-at: record # Equality filters that are applied to the occurred_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"keys":[{"description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gt","type":"iso8601 string"},{"description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gte","type":"iso8601 string"},{"description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lt","type":"iso8601 string"},{"description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lte","type":"iso8601 string"}],"type":"object"}
  --pinned: oneof<nothing, bool> # Filter by the pinned status of activity. Must be 'true' or 'false'
  --resource-type: string # Filter by the resource type. A resource is a Salesloft object that the activity is attributed to. A valid resource types must be one of person, account, crm_opportunity. Can be provided as an array
  --resource-id: list<string> # Filter by the resource id. "resource_type" filter is required to use this filter.
  --updated-at: record # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"keys":[{"description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gt","type":"iso8601 string"},{"description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gte","type":"iso8601 string"},{"description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lt","type":"iso8601 string"},{"description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lte","type":"iso8601 string"}],"type":"object"}
  --user-guid: string # Filter activities by a user's guid.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "_resource" $resource "scalar") (serialize-qp "occurred_at" $occurred_at "multi") (serialize-qp "pinned" $pinned "scalar") (serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "resource_id" $resource_id "csv") (serialize-qp "updated_at" $updated_at "multi") (serialize-qp "user_guid" $user_guid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/activity_histories" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "sort_by": $sort_by, "sort_direction": $sort_direction, "type": $type, "_resource": $resource, "occurred_at": $occurred_at, "pinned": $pinned, "resource_type": $resource_type, "resource_id": $resource_id, "updated_at": $updated_at, "user_guid": $user_guid} | compact), body: null}
}

# List bulk jobs
#
# GET /v2/bulk_jobs
export def "bulk-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: list<string> # The state of the bulk job. Accepts multiple states. Each state must be one of: open, executing, done
  --id: record # Filter by id using comparison operators. Only supports greater than (gt) comparison (i.e. id[gt]=123)
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "csv") (serialize-qp "id" $id "multi") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bulk_jobs" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"state": $state, "id": $id, "per_page": $per_page} | compact), body: null}
}

# Create a bulk job
#
# POST /v2/bulk_jobs
export def "bulk-jobs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name for your bulk job
  type: string # Type of bulk job. Must be a valid type. Follow link to the bulk job details page above to view supported types.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bulk_jobs")
  let req_body = {"name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List job data for a bulk job
#
# GET /v2/bulk_jobs/{bulk_jobs_id}/job_data
export def "bulk-jobs-job-data get" [
  bulk_jobs_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: list<string> # Filter by result status. Accepts multiple statuses. Each status must be one of pending, success, error, retrying
  --id: record # Filter by id using comparison operators. Only supports greater than (gt) comparison (i.e. id[gt]=123)
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bulk_jobs_id | is-empty) { error make --unspanned { msg: "path parameter 'bulk_jobs_id' must be non-empty" } }
  let qp = [(serialize-qp "status" $status "csv") (serialize-qp "id" $id "multi") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bulk_jobs_id: (encode-path-segment $bulk_jobs_id)} | format pattern "/v2/bulk_jobs/{bulk_jobs_id}/job_data") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"status": $status, "id": $id, "per_page": $per_page} | compact), body: null}
}

# Create job data for a bulk job
#
# POST /v2/bulk_jobs/{bulk_jobs_id}/job_data
export def "bulk-jobs-job-data create" [
  bulk_jobs_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list<string> # Array of objects containing parameters to be used to execute an instance of each. Array must be 5,000 records or less.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bulk_jobs_id | is-empty) { error make --unspanned { msg: "path parameter 'bulk_jobs_id' must be non-empty" } }
  let full_url = (build-url $base ({bulk_jobs_id: (encode-path-segment $bulk_jobs_id)} | format pattern "/v2/bulk_jobs/{bulk_jobs_id}/job_data"))
  let req_body = {"data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List job data for a completed bulk job.
#
# GET /v2/bulk_jobs/{bulk_jobs_id}/results
export def "bulk-jobs-results get" [
  bulk_jobs_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: list<string> # Filter by result status. Accepts multiple statuses. Each status must be one of pending, success, error, retrying
  --id: record # Filter by id using comparison operators. Only supports greater than (gt) comparison (i.e. id[gt]=123)
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bulk_jobs_id | is-empty) { error make --unspanned { msg: "path parameter 'bulk_jobs_id' must be non-empty" } }
  let qp = [(serialize-qp "status" $status "csv") (serialize-qp "id" $id "multi") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bulk_jobs_id: (encode-path-segment $bulk_jobs_id)} | format pattern "/v2/bulk_jobs/{bulk_jobs_id}/results") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"status": $status, "id": $id, "per_page": $per_page} | compact), body: null}
}

# Fetch a bulk job
#
# GET /v2/bulk_jobs/{id}
export def "bulk-jobs get" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/bulk_jobs/{id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a bulk job
#
# PUT /v2/bulk_jobs/{id}
export def "bulk-jobs update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name for your bulk job
  --ready-to-execute: oneof<nothing, bool> # Whether the job is ready to be executed. Must be true or false.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/bulk_jobs/{id}"))
  let req_body = {"name": $name, "ready_to_execute": $ready_to_execute} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Export a cadence
#
# GET /v2/cadence_exports/{id}.json
export def "cadence-exports get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/cadence_exports/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Import cadences from JSON
#
# POST /v2/cadence_imports.json
export def "cadence-imports-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cadence-content: record # Import data for cadence
  --settings: record # Settings for a cadence
  --sharing-settings: record # The shared settings for a cadence
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/cadence_imports.json")
  let req_body = {"cadence_content": $cadence_content, "settings": $settings, "sharing_settings": $sharing_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List cadence memberships
#
# GET /v2/cadence_memberships.json
export def "cadence-memberships-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of cadence memberships to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --person-id: int # ID of the person to find cadence memberships for
  --cadence-id: int # ID of the cadence to find cadence memberships for
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --currently-on-cadence: oneof<nothing, bool> # If true, return only cadence memberships for people currently on cadences. If false, return cadence memberships for people who have been removed from or have completed a cadence.
  --sort-by: string # Key to sort on, must be one of: added_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "person_id" $person_id "scalar") (serialize-qp "cadence_id" $cadence_id "scalar") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "currently_on_cadence" $currently_on_cadence "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cadence_memberships.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "person_id": $person_id, "cadence_id": $cadence_id, "updated_at": $updated_at, "currently_on_cadence": $currently_on_cadence, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create a cadence membership
#
# POST /v2/cadence_memberships.json
export def "cadence-memberships-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --person-id: int # ID of the person to create a cadence membership for
  --cadence-id: int # ID of the cadence to create a cadence membership for
  --user-id: int # ID of the user to create a cadence membership for. The associated cadence must be owned by the user, or it must be a team cadence
  --step-id: int # ID of the step on which the person should start the cadence. Start on first step is the default behavior without this parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "person_id" $person_id "scalar") (serialize-qp "cadence_id" $cadence_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "step_id" $step_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cadence_memberships.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"person_id": $person_id, "cadence_id": $cadence_id, "user_id": $user_id, "step_id": $step_id} | compact), body: null}
}

# Delete a cadence membership
#
# DELETE /v2/cadence_memberships/{id}.json
export def "cadence-memberships delete" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/cadence_memberships/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a cadence membership
#
# GET /v2/cadence_memberships/{id}.json
export def "cadence-memberships get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/cadence_memberships/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List cadences
#
# GET /v2/cadences.json
export def "cadences-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of cadences to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --team-cadence: oneof<nothing, bool> # Filters cadences by whether they are a team cadence or not
  --shared: oneof<nothing, bool> # Filters cadences by whether they are shared
  --owned-by-guid: list<string> # Filters cadences by the owner's guid. Multiple owner guids can be applied
  --people-addable: oneof<nothing, bool> # Filters cadences by whether they are able to have people added to them
  --name: list<string> # Filters cadences by name
  --group-ids: string # Filters by group ids. Also supports group ids passed in as a JSON array string
  --archived: oneof<nothing, bool> # Filters by whether the Cadences have been archived. Excluding this field will result in both archived and unarchived Cadences to return.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, name. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "team_cadence" $team_cadence "scalar") (serialize-qp "shared" $shared "scalar") (serialize-qp "owned_by_guid" $owned_by_guid "csv") (serialize-qp "people_addable" $people_addable "scalar") (serialize-qp "name" $name "csv") (serialize-qp "group_ids" $group_ids "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cadences.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "updated_at": $updated_at, "team_cadence": $team_cadence, "shared": $shared, "owned_by_guid": $owned_by_guid, "people_addable": $people_addable, "name": $name, "group_ids": $group_ids, "archived": $archived, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch a cadence
#
# GET /v2/cadences/{id}.json
export def "cadences get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/cadences/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List calendar events
#
# GET /v2/calendar/events
export def "calendar-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --sort-by: string # Key to sort on, must be one of: start_time. Defaults to start_time
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --start-time: string # Lower bound (inclusive) for a calendar event's end time to filter by. Must be in ISO 8601 format. Example: `2022-02-14T10:12:59+00:00`.
  --end-time: string # Upper bound (exclusive) for a calendar event's start time to filter by. Must be in ISO 8601 format. Example: `2022-02-14T10:12:59+00:00`.
  --user-guid: string # user_guid of the user who created or included as a guest to the event.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "user_guid" $user_guid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/calendar/events" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "sort_by": $sort_by, "sort_direction": $sort_direction, "start_time": $start_time, "end_time": $end_time, "user_guid": $user_guid} | compact), body: null}
}

# Upsert a calendar event
#
# POST /v2/calendar/events/upsert
export def "calendar-events-upsert create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all-day: oneof<nothing, bool> # Should be set to `true` for all day calendar events.
  --attendees: record # List of attendees of the calendar event. Example: ``` { ... "attendees": [ { "name": "Alice", "email": "alice@example.com", "status": "accepted", "organizer": true }, { "name": "Bob", "email": "bob@example.com", "status": "needsAction", "organizer": false } ] } ``` `name`: full name of the attendee `email`: email address of the attendee `status`: one of the following - needsAction, accepted, tentative, declined `organizer`: whether the attendee is the organizer of the calendar event
  calendar_id: string # Calendar ID of the calendar event owner. For the External Calendar connection use `external_{salesloft_user_guid}` format. Example: `external_00210d1a-df8a-459f-af75-89b953b618b0`.
  --canceled-at: string # Cancellation time of the calendar event, as a combined date-time value in the ISO 8601 format with a time zone offset. Example: `2022-02-14T10:12:59+00:00`.
  --description: string # Description of the calendar event
  end_time: string # End time of the calendar event, as a combined date-time value in the ISO 8601 format with a time zone offset. Example: `2022-02-14T10:12:59+00:00`. (format: date)
  i_cal_uid: string # icalUID of the calendar event. Unique identifier for a calendar event across calendars. Used as an upsert key.
  id: string # Id of the calendar event, different for each occurrence in a recurring series. Used as an upsert key.
  --location: string # Location of the calendar event as free-form text.
  --organizer: string # Email address of the organizer
  --recurring: oneof<nothing, bool> # Should be set to `true` if this is one of recurring series calendar event.
  start_time: string # Start time of the calendar event, as a combined date-time value in the ISO 8601 format with a time zone offset. Example: `2022-02-14T10:12:59+00:00`. (format: date)
  --status: string # Status of the calendar event. Depending on the status, the calendar event will or will not impact user's availability. Possible values: `confirmed`, `tentative`, `cancelled`. Example: `confirmed`.
  --title: string # Title of the calendar event
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/calendar/events/upsert")
  let req_body = {"all_day": $all_day, "attendees": $attendees, "calendar_id": $calendar_id, "canceled_at": $canceled_at, "description": $description, "end_time": $end_time, "i_cal_uid": $i_cal_uid, "id": $id, "location": $location, "organizer": $organizer, "recurring": $recurring, "start_time": $start_time, "status": $status, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List call data records
#
# GET /v2/call_data_records.json
export def "call-data-records-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of call data records to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --has-call: oneof<nothing, bool> # Return only call data records which have or do not have a call logged for them
  --created-at: list<string> # Equality filters that are applied to the created_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --user-guid: list<string> # Filters list to only include guids
  --person-id: list<int> # Filters list by person_id. Multiple person ids can be applied
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "has_call" $has_call "scalar") (serialize-qp "created_at" $created_at "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "user_guid" $user_guid "csv") (serialize-qp "person_id" $person_id "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/call_data_records.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "has_call": $has_call, "created_at": $created_at, "updated_at": $updated_at, "user_guid": $user_guid, "person_id": $person_id, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch a call data record
#
# GET /v2/call_data_records/{id}.json
export def "call-data-records get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/call_data_records/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List call dispositions
#
# GET /v2/call_dispositions.json
export def "call-dispositions-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string # Key to sort on, must be one of: name, updated_at. Defaults to name
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to ASC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/call_dispositions.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# List call sentiments
#
# GET /v2/call_sentiments.json
export def "call-sentiments-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filters call sentiments by name
  --sort-by: string # Key to sort on, must be one of: name, updated_at. Defaults to name
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to ASC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/call_sentiments.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create Conversations Call
#
# POST /v2/conversations/calls
export def "conversations-calls create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-created-at: string # Timestamp for when the call started. If not provided, will default to the time the request was received
  --direction: string # Call direction
  duration: float # Duration of call in seconds
  --body-from: string # Phone number that call was made from
  recording: record # Object containing recording info including the audio file (.mp3, .wav, .ogg, .m4a)
  --body-to: string # Phone number that was called
  --user-guid: string # Guid of the Salesloft User to assign the call to. If not provided, will default to the user within the authentication token
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/conversations/calls")
  let req_body = {"call_created_at": $call_created_at, "direction": $direction, "duration": $duration, "from": $body_from, "recording": $recording, "to": $body_to, "user_guid": $user_guid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List crm activities
#
# GET /v2/crm_activities.json
export def "crm-activities-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of crm activities to fetch.
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/crm_activities.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "updated_at": $updated_at, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch a crm activity
#
# GET /v2/crm_activities/{id}.json
export def "crm-activities get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/crm_activities/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List crm activity fields
#
# GET /v2/crm_activity_fields.json
export def "crm-activity-fields-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: string # Return only records with this source
  --sort-by: string # Key to sort on, must be one of: title, updated_at. Defaults to title
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to ASC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/crm_activity_fields.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"source": $qp_source, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# List crm users
#
# GET /v2/crm_users.json
export def "crm-users-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of crm users to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --crm-id: list<string> # Filters crm users by crm_ids
  --user-id: list<int> # Filters crm users by user_ids
  --user-guid: list<string> # Filters crm users by user guids
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
  --sort-by: string # Key to sort on, must be one of: id, updated_at. Defaults to id
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "crm_id" $crm_id "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "user_guid" $user_guid "csv") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/crm_users.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "crm_id": $crm_id, "user_id": $user_id, "user_guid": $user_guid, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts, "sort_by": $sort_by, "sort_direction": $sort_direction} | compact), body: null}
}

# List custom fields
#
# GET /v2/custom_fields.json
export def "custom-fields-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of custom fields to fetch.
  --field-type: string # Type of field to fetch. Value must be one of: person, company, opportunity
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, name. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "field_type" $field_type "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/custom_fields.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "field_type": $field_type, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create a custom field
#
# POST /v2/custom_fields.json
export def "custom-fields-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-type: string # The field type of the custom field. Value must be one of: person, company, opportunity
  name: string # The name of the custom field
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/custom_fields.json")
  let req_body = {"field_type": $field_type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a custom field
#
# DELETE /v2/custom_fields/{id}.json
export def "custom-fields delete" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/custom_fields/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a custom field
#
# GET /v2/custom_fields/{id}.json
export def "custom-fields get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/custom_fields/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a custom field
#
# PUT /v2/custom_fields/{id}.json
export def "custom-fields update" [
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
  --field-type: string # The field type of the custom field. Value must be one of: person, company, opportunity
  --name: string # The name of the custom field
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/custom_fields/{id}.json"))
  let req_body = {"field_type": $field_type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List email template attachments
#
# GET /v2/email_template_attachments.json
export def "email-template-attachments-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of email template attachments to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --email-template-id: list<int> # Filters email template attachments by email template IDs
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "email_template_id" $email_template_id "csv") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/email_template_attachments.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "email_template_id": $email_template_id, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# List email templates
#
# GET /v2/email_templates.json
export def "email-templates-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of email templates to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --linked-to-team-template: oneof<nothing, bool> # Filters email templates by whether they are linked to a team template or not
  --search: string # Filters email templates by title or subject
  --tag-ids: list<int> # Filters email templates by tags applied to the template by tag ID, not to exceed 100 IDs
  --tag: list<string> # Filters email templates by tags applied to the template, not to exceed 100 tags
  --filter-by-owner: oneof<nothing, bool> # Filters email templates by current authenticated user
  --group-id: list<int> # Filters email templates by groups applied to the template by group ID. Not to exceed 500 IDs. Returns templates that are assigned to any of the group ids.
  --include-cadence-templates: oneof<nothing, bool> # Filters email templates based on whether or not the template has been used on a cadence
  --include-archived-templates: oneof<nothing, bool> # Filters email templates to include archived templates or not
  --cadence-id: list<int> # Filters email templates to those belonging to the cadence. Not to exceed 100 IDs. If a record can't be found, that record won't be returned and your request will be successful
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, last_used_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "linked_to_team_template" $linked_to_team_template "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "tag_ids" $tag_ids "csv") (serialize-qp "tag" $tag "csv") (serialize-qp "filter_by_owner" $filter_by_owner "scalar") (serialize-qp "group_id" $group_id "csv") (serialize-qp "include_cadence_templates" $include_cadence_templates "scalar") (serialize-qp "include_archived_templates" $include_archived_templates "scalar") (serialize-qp "cadence_id" $cadence_id "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/email_templates.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "updated_at": $updated_at, "linked_to_team_template": $linked_to_team_template, "search": $search, "tag_ids": $tag_ids, "tag": $tag, "filter_by_owner": $filter_by_owner, "group_id": $group_id, "include_cadence_templates": $include_cadence_templates, "include_archived_templates": $include_archived_templates, "cadence_id": $cadence_id, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch an email template
#
# GET /v2/email_templates/{id}.json
export def "email-templates get" [
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
  --include-signature: oneof<nothing, bool> # Optionally will return the templates with the current user's email signature
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_signature" $include_signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/email_templates/{id}.json") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_signature": $include_signature} | compact), body: null}
}

# Create an External Email
#
# POST /v2/external_emails.json
export def "external-emails-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  mailbox: string # Email address of mailbox email was sent to
  --body-raw: string # Base64 encoded MIME email content
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/external_emails.json")
  let req_body = {"mailbox": $mailbox, "raw": $body_raw} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List groups
#
# GET /v2/groups.json
export def "groups-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of groups to fetch.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/groups.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "sort_by": $sort_by, "sort_direction": $sort_direction} | compact), body: null}
}

# Fetch a group
#
# GET /v2/groups/{id}.json
export def "groups get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/groups/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List imports
#
# GET /v2/imports.json
export def "imports-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of imports to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --user-ids: list<int> # ID of users to fetch imports for. Using this filter will return an empty array for non-admin users who request other user's imports
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to created_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "user_ids" $user_ids "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/imports.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "user_ids": $user_ids, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create an import
#
# POST /v2/imports.json
export def "imports-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name, recommended to be easily identifiable to a user
  --user-id: int # ID of the User that owns this Import
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/imports.json")
  let req_body = {"name": $name, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete an import
#
# DELETE /v2/imports/{id}.json
export def "imports delete" [
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
  --undo: string # Whether to delete people on this Import. Possible values are: [not present], all, single. 'single' will delete people who are only present in this Import. 'all' will delete people even if they are present in other Imports. Not specifying this parameter will not delete any people
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "undo" $undo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/imports/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"undo": $undo} | compact), body: null}
}

# Fetch an import
#
# GET /v2/imports/{id}.json
export def "imports get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/imports/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an import
#
# PUT /v2/imports/{id}.json
export def "imports update" [
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
  --name: string # Name, recommended to be easily identifiable to a user
  --user-id: int # ID of the User that owns this Import
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/imports/{id}.json"))
  let req_body = {"name": $name, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Create an Live Website Tracking Parameter
#
# POST /v2/live_website_tracking_parameters.json
export def "live-website-tracking-parameters-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  person_id: int # The person to create the LiveWebsiteTrackingParameter for
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/live_website_tracking_parameters.json")
  let req_body = {"person_id": $person_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch current user
#
# GET /v2/me.json
export def "me-json get" [
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
  let full_url = (build-url $base "/v2/me.json")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List meetings
#
# GET /v2/meetings.json
export def "meetings-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of meetings to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --status: string # Filters meetings by status. Possible values are: pending, booked, failed, retry
  --person-id: string # Filters meetings by person_id. Multiple person ids can be applied
  --account-id: string # Filters meetings by account_id. Multiple account ids can be applied
  --person-ids: list<int> # Filters meetings by person_id. Multiple person ids can be applied
  --event-ids: list<int> # Filters meetings by event IDs
  --i-cal-uids: list<string> # Filters meetings by UIDs provided by calendar provider
  --task-ids: list<int> # Filters meetings by task_id. Multiple task ids can be applied
  --include-meetings-settings: oneof<nothing, bool> # Flag to indicate whether to include owned_by_meetings_settings and booked_by_meetings_settings objects
  --start-time: list<string> # Equality filters that are applied to the start_time field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --user-guids: list<string> # Filters meetings by user_guid. Multiple user guids can be applied
  --show-deleted: oneof<nothing, bool> # Whether to include deleted events in the result
  --sort-by: string # Key to sort on, must be one of: start_time, created_at, updated_at. Defaults to start_time
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "status" $status "scalar") (serialize-qp "person_id" $person_id "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "person_ids" $person_ids "csv") (serialize-qp "event_ids" $event_ids "csv") (serialize-qp "i_cal_uids" $i_cal_uids "csv") (serialize-qp "task_ids" $task_ids "csv") (serialize-qp "include_meetings_settings" $include_meetings_settings "scalar") (serialize-qp "start_time" $start_time "csv") (serialize-qp "user_guids" $user_guids "csv") (serialize-qp "show_deleted" $show_deleted "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/meetings.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "status": $status, "person_id": $person_id, "account_id": $account_id, "person_ids": $person_ids, "event_ids": $event_ids, "i_cal_uids": $i_cal_uids, "task_ids": $task_ids, "include_meetings_settings": $include_meetings_settings, "start_time": $start_time, "user_guids": $user_guids, "show_deleted": $show_deleted, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# List meeting settings
#
# POST /v2/meetings/settings/searches.json
export def "meetings-settings-searches-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-guids: list<string> # Filters meeting settings by array of user_guids
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --calendar-type: string # Filters meeting settings by calendar type
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_guids" $user_guids "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "calendar_type" $calendar_type "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/meetings/settings/searches.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_guids": $user_guids, "updated_at": $updated_at, "calendar_type": $calendar_type, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Update a meeting setting
#
# PUT /v2/meetings/settings/{id}.json
export def "meetings-settings update" [
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
  --allow-booking-on-behalf: oneof<nothing, bool> # Allow other team members to schedule on you behalf.
  --allow-booking-overtime: oneof<nothing, bool> # Allow team members to insert available time outside your working hours.
  --allow-event-overlap: oneof<nothing, bool> # Allow team members to double book events on your calendar.
  --availability-limit: int # The number of days out the user allows a prospect to schedule a meeting
  --availability-limit-enabled: oneof<nothing, bool> # If Availability Limits have been turned on
  --buffer-time-duration: int # Default buffer duration in minutes set by a user
  --calendar-type: string # Calendar type
  --default-meeting-length: int # Default meeting length in minutes set by the user
  --description: string # Default description of the meeting
  --enable-calendar-sync: oneof<nothing, bool> # Determines if a user enabled Calendar Sync feature
  --enable-dynamic-location: oneof<nothing, bool> # Determines if location will be filled via third-party service (Zoom, GoToMeeting, etc.)
  --location: string # Default location of the meeting
  --primary-calendar-connection-failed: oneof<nothing, bool> # Determines if the user lost calendar connection
  --primary-calendar-id: string # ID of the primary calendar
  --primary-calendar-name: string # Display name of the primary calendar
  --schedule-buffer-enabled: oneof<nothing, bool> # Determines if meetings are scheduled with a 15 minute buffer between them
  --schedule-delay: int # The number of hours in advance a user requires someone to a book a meeting with them
  --share-event-detail: oneof<nothing, bool> # Allow team members to see the details of events on your calendar.
  --time-zone: string # Time zone for current calendar
  --times-available: record # Times available set by a user that can be used to book meetings
  --title: string # Default title of the meeting
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/meetings/settings/{id}.json"))
  let req_body = {"allow_booking_on_behalf": $allow_booking_on_behalf, "allow_booking_overtime": $allow_booking_overtime, "allow_event_overlap": $allow_event_overlap, "availability_limit": $availability_limit, "availability_limit_enabled": $availability_limit_enabled, "buffer_time_duration": $buffer_time_duration, "calendar_type": $calendar_type, "default_meeting_length": $default_meeting_length, "description": $description, "enable_calendar_sync": $enable_calendar_sync, "enable_dynamic_location": $enable_dynamic_location, "location": $location, "primary_calendar_connection_failed": $primary_calendar_connection_failed, "primary_calendar_id": $primary_calendar_id, "primary_calendar_name": $primary_calendar_name, "schedule_buffer_enabled": $schedule_buffer_enabled, "schedule_delay": $schedule_delay, "share_event_detail": $share_event_detail, "time_zone": $time_zone, "times_available": $times_available, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Update a meeting
#
# PUT /v2/meetings/{id}.json
export def "meetings update" [
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
  --event-id: string # Meeting ID from the calendar provider
  --i-cal-uid: string # Meeting unique identifier (iCalUID)
  --no-show: oneof<nothing, bool> # Whether the meeting is a No Show meeting
  --status: string # Status of the meeting creation progress. Possible values are: pending, booked, failed, retry
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/meetings/{id}.json"))
  let req_body = {"event_id": $event_id, "i_cal_uid": $i_cal_uid, "no_show": $no_show, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch the MIME content for email
#
# GET /v2/mime_email_payloads/{id}.json
export def "mime-email-payloads get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/mime_email_payloads/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List notes
#
# GET /v2/notes.json
export def "notes-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associated-with-type: string # Case insensitive type of item with which the note is associated. Value must be one of: person, account
  --associated-with-id: int # ID of the item with which the note is associated. The associated_with_type must also be present if this parameter is used
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --ids: list<int> # IDs of notes to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "associated_with_type" $associated_with_type "scalar") (serialize-qp "associated_with_id" $associated_with_id "scalar") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "ids" $ids "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/notes.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"associated_with_type": $associated_with_type, "associated_with_id": $associated_with_id, "updated_at": $updated_at, "ids": $ids, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create a note
#
# POST /v2/notes.json
export def "notes-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  associated_with_id: int # ID of the item with which the note is associated
  associated_with_type: string # Case insensitive type of item with which the note is associated. Value must be one of: person, account
  --call-id: int # ID of the call with which the note is associated. The call cannot already have a note
  content: string # The content of the note
  --skip-crm-sync: oneof<nothing, bool> # Boolean indicating if the CRM sync should be skipped. No syncing will occur if true
  --subject: string # The subject of the note's crm activity, defaults to 'Note'
  --user-guid: string # The user to create the note for. Only team admins may create notes on behalf of other users. Defaults to the requesting user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notes.json")
  let req_body = {"associated_with_id": $associated_with_id, "associated_with_type": $associated_with_type, "call_id": $call_id, "content": $content, "skip_crm_sync": $skip_crm_sync, "subject": $subject, "user_guid": $user_guid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a note
#
# DELETE /v2/notes/{id}.json
export def "notes delete" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/notes/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a note
#
# GET /v2/notes/{id}.json
export def "notes get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/notes/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a note
#
# PUT /v2/notes/{id}.json
export def "notes update" [
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
  --call-id: int # ID of the call with which the note is associated. The call cannot already have a note. If the note is associated to a call already, it will become associated to the requested call
  content: string # The content of the note
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/notes/{id}.json"))
  let req_body = {"call_id": $call_id, "content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Create an ongoing action
#
# POST /v2/ongoing_actions.json
export def "ongoing-actions-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-id: int # Action that is being marked ongoing. This will validate that the action is still valid before modifying it. Ongoing actions can not be marked ongoing.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/ongoing_actions.json")
  let req_body = {"action_id": $action_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetches a list of emails ready to be sent by an external email service. Only emails sent with an External Email Client will appear here.
#
# GET /v2/pending_emails.json
export def "pending-emails-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/pending_emails.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Updates the status of an email sent by an External Email Client
#
# PUT /v2/pending_emails/{id}.json
export def "pending-emails update" [
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
  --error-message: string # The error message indicating why the email failed to send
  message_id: string # The message id of the email that was sent
  --sent-at: string # The time that the email was actually sent in iso8601 format
  status: string # Delivery status of the email. Valid statuses are 'sent' and 'failed'
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/pending_emails/{id}.json"))
  let req_body = {"error_message": $error_message, "message_id": $message_id, "sent_at": $sent_at, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List people
#
# GET /v2/people.json
export def "people-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of people to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --email-addresses: list<string> # Filters people by email address. Multiple emails can be applied. An additional value of "_is_null" can be passed to filter people that do not have an email address.
  --owned-by-guid: list<string> # Filters people by the owner's guid. Multiple owner guids can be applied
  --person-stage-id: list<int> # Includes people that have a given person_stage. Multiple person stage ids can be applied. An additional value of "_is_null" can be passed to filter people that do not have a stage set.
  --crm-id: list<string> # Filters people by crm_id. Multiple crm ids can be applied
  --owner-crm-id: list<string> # Filters people by owner_crm_id. Multiple owner_crm_ids can be applied. An additional value of "_is_null" can be passed to filter people that are unowned. A "_not_in" modifier can be used to exclude specific owner_crm_ids. Example: v2/people?owner_crm_id[_not_in]=id
  --do-not-contact: oneof<nothing, bool> # Includes people that have a given do_not_contact property
  --can-email: oneof<nothing, bool> # Includes people that can be emailed given do_not_contact and contact_restrictions property
  --can-call: oneof<nothing, bool> # Includes people that can be called given do_not_contact and contact_restrictions property
  --can-text: oneof<nothing, bool> # Includes people that can be sent a text message given do_not_contact and contact_restrictions property
  --account-id: list<int> # Filters people by the account they are linked to. Multiple account ids can be applied
  --custom-fields: record # Filters by people matching all given custom fields. The custom field names are case-sensitive, but the provided values are case-insensitive. Example: v2/people?custom_fields[custom_field_name]=custom_field_value
  --import-id: list<int> # Filters people that were imported by the given import ids. Multiple import ids can be applied. An additional value of "_is_null" can be passed to filter people that were not imported.
  --job-seniority: list<string> # Filters people by job seniorty. Multiple job seniorities can be applied. An additional value of "_is_null" can be passed to filter people do not have a job_seniority.
  --tag-id: list<int> # Filters people by the tag ids applied to the person. Multiple tag ids can be applied.
  --owner-is-active: oneof<nothing, bool> # Filters people by whether the owner is active or not.
  --cadence-id: list<int> # Filters people by the cadence that they are currently on. Multiple cadence_ids can be applied. An additional value of "_is_null" can be passed to filter people that are not on a cadence.
  --starred-by-guid: list<string> # Filters people who have been starred by the user guids given.
  --replied: oneof<nothing, bool> # Filters people by whether or not they have replied to an email or not.
  --bounced: oneof<nothing, bool> # Filters people by whether an email that was sent to them bounced or not.
  --success: oneof<nothing, bool> # Filters people by whether or not they have been marked as a success or not.
  --eu-resident: oneof<nothing, bool> # Filters people by whether or not they are marked as an European Union Resident or not.
  --title: list<string> # Filters people by their title by exact match. Supports partial matching
  --country: list<string> # Filters people by their country by exact match. Supports partial matching
  --state: list<string> # Filters people by their state by exact match. Supports partial matching
  --city: list<string> # Filters people by their city by exact match. Supports partial matching
  --last-contacted: record # Equality filters that are applied to the last_contacted field. A single filter can be used by itself or combined with other filters to create a range. Additional values of "_is_null" or "_is_not_null" can be passed to filter records that either have no timestamp value or any timestamp value. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --created-at: record # Equality filters that are applied to the last_contacted field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --new: oneof<nothing, bool> # Filters people by whether or not that person is on a cadence or if they have been contacted in any way.
  --phone-number: oneof<nothing, bool> # Filter people by whether or not they have a phone number or not
  --locales: list<string> # Filters people by locales. Multiple locales can be applied. An additional value of "Null" can be passed to filter people that do not have a locale.
  --owner-id: list<int> # Filters people by owner_id. Multiple owner_ids can be applied.
  --query: string # For internal use only. This field does not comply with our backwards compatibility policies. This filter is for authenticated users of Salesloft only and will not work for OAuth Applications. Filters people by the string provided. Can search and filter by name, title, industry, email_address and linked account name.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, last_contacted_at, name, title, job_seniority, call_count, sent_emails, clicked_emails, replied_emails, viewed_emails, account, cadence_stage_name. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "email_addresses" $email_addresses "csv") (serialize-qp "owned_by_guid" $owned_by_guid "csv") (serialize-qp "person_stage_id" $person_stage_id "csv") (serialize-qp "crm_id" $crm_id "csv") (serialize-qp "owner_crm_id" $owner_crm_id "csv") (serialize-qp "do_not_contact" $do_not_contact "scalar") (serialize-qp "can_email" $can_email "scalar") (serialize-qp "can_call" $can_call "scalar") (serialize-qp "can_text" $can_text "scalar") (serialize-qp "account_id" $account_id "csv") (serialize-qp "custom_fields" $custom_fields "multi") (serialize-qp "import_id" $import_id "csv") (serialize-qp "job_seniority" $job_seniority "csv") (serialize-qp "tag_id" $tag_id "csv") (serialize-qp "owner_is_active" $owner_is_active "scalar") (serialize-qp "cadence_id" $cadence_id "csv") (serialize-qp "starred_by_guid" $starred_by_guid "csv") (serialize-qp "replied" $replied "scalar") (serialize-qp "bounced" $bounced "scalar") (serialize-qp "success" $success "scalar") (serialize-qp "eu_resident" $eu_resident "scalar") (serialize-qp "title" $title "csv") (serialize-qp "country" $country "csv") (serialize-qp "state" $state "csv") (serialize-qp "city" $city "csv") (serialize-qp "last_contacted" $last_contacted "multi") (serialize-qp "created_at" $created_at "multi") (serialize-qp "new" $new "scalar") (serialize-qp "phone_number" $phone_number "scalar") (serialize-qp "locales" $locales "csv") (serialize-qp "owner_id" $owner_id "csv") (serialize-qp "_query" $query "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/people.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "updated_at": $updated_at, "email_addresses": $email_addresses, "owned_by_guid": $owned_by_guid, "person_stage_id": $person_stage_id, "crm_id": $crm_id, "owner_crm_id": $owner_crm_id, "do_not_contact": $do_not_contact, "can_email": $can_email, "can_call": $can_call, "can_text": $can_text, "account_id": $account_id, "custom_fields": $custom_fields, "import_id": $import_id, "job_seniority": $job_seniority, "tag_id": $tag_id, "owner_is_active": $owner_is_active, "cadence_id": $cadence_id, "starred_by_guid": $starred_by_guid, "replied": $replied, "bounced": $bounced, "success": $success, "eu_resident": $eu_resident, "title": $title, "country": $country, "state": $state, "city": $city, "last_contacted": $last_contacted, "created_at": $created_at, "new": $new, "phone_number": $phone_number, "locales": $locales, "owner_id": $owner_id, "_query": $query, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create a person
#
# POST /v2/people.json
export def "people-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # ID of the Account to link this person to
  --autotag-date: oneof<nothing, bool> # Whether the date should be added to this person as a tag. Default is false. The tag will be Y-m-d format.
  --city: string # City
  --contact-restrictions: list<string> # Specific methods of communication to prevent for this person. This will prevent individual execution of these communication types as well as automatically skip cadence steps of this communication type for this person in SalesLoft. Values currently accepted: call, email, message
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either a Lead (00Q) or Contact (003) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "person:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: record # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --do-not-contact: oneof<nothing, bool> # Whether or not this person has opted out of all communication. Setting this value to true prevents this person from being called, emailed, or added to a cadence in SalesLoft. If this person is currently in a cadence, they will be removed.
  --email-address: string # Email address
  --first-name: string # First name
  --home-phone: string # Home phone without formatting
  --import-id: int # ID of the Import this person is a part of. A person can be part of multiple imports, but this ID will always be the most recent Import
  --job-seniority: string # The Job Seniority of a Person, must be one of director, executive, individual_contributor, manager, vice_president, unknown
  --last-name: string # Last name
  --linkedin-url: string # Linkedin URL
  --locale: string # Time locale of the person
  --mobile-phone: string # Mobile phone without formatting
  --owner-id: int # ID of the User that owns this person
  --person-company-industry: string # Company industry. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-name: string # Company name. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-website: string # Company website. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-stage-id: int # ID of the PersonStage of this person
  --personal-email-address: string # Personal email address
  --personal-website: string # The website of this person
  --phone: string # Phone without formatting
  --phone-extension: string # Phone extension without formatting
  --secondary-email-address: string # Alternate email address
  --state: string # State
  --tags: list<string> # All tags applied to this person
  --title: string # Job title
  --twitter-handle: string # The twitter handle of this person
  --work-city: string # Work location - city
  --work-country: string # Work location - country
  --work-state: string # Work location - state
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/people.json")
  let req_body = {"account_id": $account_id, "autotag_date": $autotag_date, "city": $city, "contact_restrictions": $contact_restrictions, "country": $country, "crm_id": $crm_id, "crm_id_type": $crm_id_type, "custom_fields": $custom_fields, "do_not_contact": $do_not_contact, "email_address": $email_address, "first_name": $first_name, "home_phone": $home_phone, "import_id": $import_id, "job_seniority": $job_seniority, "last_name": $last_name, "linkedin_url": $linkedin_url, "locale": $locale, "mobile_phone": $mobile_phone, "owner_id": $owner_id, "person_company_industry": $person_company_industry, "person_company_name": $person_company_name, "person_company_website": $person_company_website, "person_stage_id": $person_stage_id, "personal_email_address": $personal_email_address, "personal_website": $personal_website, "phone": $phone, "phone_extension": $phone_extension, "secondary_email_address": $secondary_email_address, "state": $state, "tags": $tags, "title": $title, "twitter_handle": $twitter_handle, "work_city": $work_city, "work_country": $work_country, "work_state": $work_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a person
#
# DELETE /v2/people/{id}.json
export def "people delete" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/people/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a person
#
# GET /v2/people/{id}.json
export def "people get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/people/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a person
#
# PUT /v2/people/{id}.json
export def "people update" [
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
  --account-id: int # ID of the Account to link this person to
  --city: string # City
  --contact-restrictions: list<string> # Specific methods of communication to prevent for this person. This will prevent individual execution of these communication types as well as automatically skip cadence steps of this communication type for this person in SalesLoft. Values currently accepted: call, email, message
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either a Lead (00Q) or Contact (003) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "person:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: record # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --do-not-contact: oneof<nothing, bool> # Whether or not this person has opted out of all communication. Setting this value to true prevents this person from being called, emailed, or added to a cadence in SalesLoft. If this person is currently in a cadence, they will be removed.
  --email-address: string # Email address
  --first-name: string # First name
  --home-phone: string # Home phone without formatting
  --import-id: int # ID of the Import this person is a part of. A person can be part of multiple imports, but this ID will always be the most recent Import
  --job-seniority: string # The Job Seniority of a Person, must be one of director, executive, individual_contributor, manager, vice_president, unknown
  --last-name: string # Last name
  --linkedin-url: string # Linkedin URL
  --locale: string # Time locale of the person
  --mobile-phone: string # Mobile phone without formatting
  --owner-id: int # ID of the User that owns this person
  --person-company-industry: string # Company industry. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-name: string # Company name. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-website: string # Company website. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-stage-id: int # ID of the PersonStage of this person
  --personal-email-address: string # Personal email address
  --personal-website: string # The website of this person
  --phone: string # Phone without formatting
  --phone-extension: string # Phone extension without formatting
  --secondary-email-address: string # Alternate email address
  --state: string # State
  --tags: list<string> # All tags applied to this person
  --title: string # Job title
  --twitter-handle: string # The twitter handle of this person
  --work-city: string # Work location - city
  --work-country: string # Work location - country
  --work-state: string # Work location - state
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/people/{id}.json"))
  let req_body = {"account_id": $account_id, "city": $city, "contact_restrictions": $contact_restrictions, "country": $country, "crm_id": $crm_id, "crm_id_type": $crm_id_type, "custom_fields": $custom_fields, "do_not_contact": $do_not_contact, "email_address": $email_address, "first_name": $first_name, "home_phone": $home_phone, "import_id": $import_id, "job_seniority": $job_seniority, "last_name": $last_name, "linkedin_url": $linkedin_url, "locale": $locale, "mobile_phone": $mobile_phone, "owner_id": $owner_id, "person_company_industry": $person_company_industry, "person_company_name": $person_company_name, "person_company_website": $person_company_website, "person_stage_id": $person_stage_id, "personal_email_address": $personal_email_address, "personal_website": $personal_website, "phone": $phone, "phone_extension": $phone_extension, "secondary_email_address": $secondary_email_address, "state": $state, "tags": $tags, "title": $title, "twitter_handle": $twitter_handle, "work_city": $work_city, "work_country": $work_country, "work_state": $work_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List person stages
#
# GET /v2/person_stages.json
export def "person-stages-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of person stages to fetch.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/person_stages.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create a person stage
#
# POST /v2/person_stages.json
export def "person-stages-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new stage
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/person_stages.json")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete an person stage
#
# DELETE /v2/person_stages/{id}.json
export def "person-stages delete" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/person_stages/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a person stage
#
# GET /v2/person_stages/{id}.json
export def "person-stages get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/person_stages/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a person stage
#
# PUT /v2/person_stages/{id}.json
export def "person-stages update" [
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
  name: string # The name of the stage.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/person_stages/{id}.json"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Upsert a person
#
# POST /v2/person_upserts.json
export def "person-upserts-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # ID of the Account to link this person to
  --city: string # City
  --contact-restrictions: list<string> # Specific methods of communication to prevent for this person. This will prevent individual execution of these communication types as well as automatically skip cadence steps of this communication type for this person in SalesLoft. Values currently accepted: call, email, message
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either a Lead (00Q) or Contact (003) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "person:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: record # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --do-not-contact: oneof<nothing, bool> # Whether or not this person has opted out of all communication. Setting this value to true prevents this person from being called, emailed, or added to a cadence in SalesLoft. If this person is currently in a cadence, they will be removed.
  --email-address: string # Email address
  --first-name: string # First name
  --home-phone: string # Home phone without formatting
  --id: int # ID of the person to update. Used if the upsert_key=id. When id and another upsert_key are provided, the request will fail if the upsert record id and id parameter don't match.
  --import-id: int # ID of the Import this person is a part of. A person can be part of multiple imports, but this ID will always be the most recent Import
  --job-seniority: string # The Job Seniority of a Person, must be one of director, executive, individual_contributor, manager, vice_president, unknown
  --last-name: string # Last name
  --linkedin-url: string # Linkedin URL
  --locale: string # Time locale of the person
  --mobile-phone: string # Mobile phone without formatting
  --owner-id: int # ID of the User that owns this person
  --person-company-industry: string # Company industry. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-name: string # Company name. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-website: string # Company website. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-stage-id: int # ID of the PersonStage of this person
  --personal-email-address: string # Personal email address
  --personal-website: string # The website of this person
  --phone: string # Phone without formatting
  --phone-extension: string # Phone extension without formatting
  --secondary-email-address: string # Alternate email address
  --state: string # State
  --tags: list<string> # All tags applied to this person
  --title: string # Job title
  --twitter-handle: string # The twitter handle of this person
  --upsert-key: string # Name of the parameter to upsert on. The field must be provided in the input parameters, or the request will fail. The request will also fail if there are multiple records matched by the upsert field. This can occur if intentional duplicates by email address is enabled. If upsert_key is not provided, this endpoint will not update an existing record. Valid options are: id, crm_id, email_address. If crm_id is provided, then a valid crm_id_type must be provided, as documented for the person create and update endpoints.
  --work-city: string # Work location - city
  --work-country: string # Work location - country
  --work-state: string # Work location - state
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/person_upserts.json")
  let req_body = {"account_id": $account_id, "city": $city, "contact_restrictions": $contact_restrictions, "country": $country, "crm_id": $crm_id, "crm_id_type": $crm_id_type, "custom_fields": $custom_fields, "do_not_contact": $do_not_contact, "email_address": $email_address, "first_name": $first_name, "home_phone": $home_phone, "id": $id, "import_id": $import_id, "job_seniority": $job_seniority, "last_name": $last_name, "linkedin_url": $linkedin_url, "locale": $locale, "mobile_phone": $mobile_phone, "owner_id": $owner_id, "person_company_industry": $person_company_industry, "person_company_name": $person_company_name, "person_company_website": $person_company_website, "person_stage_id": $person_stage_id, "personal_email_address": $personal_email_address, "personal_website": $personal_website, "phone": $phone, "phone_extension": $phone_extension, "secondary_email_address": $secondary_email_address, "state": $state, "tags": $tags, "title": $title, "twitter_handle": $twitter_handle, "upsert_key": $upsert_key, "work_city": $work_city, "work_country": $work_country, "work_state": $work_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List phone number assignments
#
# GET /v2/phone_number_assignments.json
export def "phone-number-assignments-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of phone number assignments to fetch
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/phone_number_assignments.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch a phone number assignment
#
# GET /v2/phone_number_assignments/{id}.json
export def "phone-number-assignments get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/phone_number_assignments/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List caller ids
#
# GET /v2/phone_numbers/caller_ids.json
export def "phone-numbers-caller-ids-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-number: string # E.164 Phone Number
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "phone_number" $phone_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/phone_numbers/caller_ids.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"phone_number": $phone_number} | compact), body: null}
}

# Fetch recording setting
#
# GET /v2/phone_numbers/recording_settings/{id}.json
export def "phone-numbers-recording-settings get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/phone_numbers/recording_settings/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List saved list views
#
# GET /v2/saved_list_views.json
export def "saved-list-views-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of saved list views to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --view: string # Type of saved list views to fetch.
  --sort-by: string # Key to sort on, must be one of: name. Defaults to name
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "view" $view "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/saved_list_views.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "view": $view, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create a saved list view
#
# POST /v2/saved_list_views.json
export def "saved-list-views-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-default: oneof<nothing, bool> # Whether the saved list view is the default
  name: string # The name of the saved list view
  view: string # The type of objects in the saved list view. Value must be one of: people, companies, or recordings
  --view-params: string # JSON object of list view parameters
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/saved_list_views.json")
  let req_body = {"is_default": $is_default, "name": $name, "view": $view, "view_params": $view_params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a saved list view
#
# DELETE /v2/saved_list_views/{id}.json
export def "saved-list-views delete" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/saved_list_views/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a saved list view
#
# GET /v2/saved_list_views/{id}.json
export def "saved-list-views get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/saved_list_views/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a saved list view
#
# PUT /v2/saved_list_views/{id}.json
export def "saved-list-views update" [
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
  --is-default: oneof<nothing, bool> # Whether the saved list view is the default
  --name: string # The name of the saved list view
  --view-params: string # JSON object of list view parameters
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/saved_list_views/{id}.json"))
  let req_body = {"is_default": $is_default, "name": $name, "view_params": $view_params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List steps
#
# GET /v2/steps.json
export def "steps-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of steps to fetch.
  --cadence-id: int # Filter by cadence ID
  --type: string # Filter by step type
  --has-due-actions: oneof<nothing, bool> # Filter by whether a step has due actions
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "cadence_id" $cadence_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "has_due_actions" $has_due_actions "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/steps.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "cadence_id": $cadence_id, "type": $type, "has_due_actions": $has_due_actions, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch a step
#
# GET /v2/steps/{id}.json
export def "steps get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/steps/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List successes
#
# GET /v2/successes.json
export def "successes-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of successes to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --person-id: list<int> # Filters successes by person_id. Multiple person ids can be applied
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, succeeded_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "person_id" $person_id "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/successes.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "person_id": $person_id, "updated_at": $updated_at, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# List team tags
#
# GET /v2/tags.json
export def "tags-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filters tags by name
  --ids: list<int> # Filters tags by their IDs
  --sort-by: string # Key to sort on, must be one of: name. Defaults to name
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "ids" $ids "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/tags.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "ids": $ids, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# List tasks
#
# GET /v2/tasks.json
export def "tasks-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of tasks to fetch.
  --user-id: list<int> # Filters tasks by the user to which they are assigned.
  --person-id: list<int> # Filters tasks by the person to which they are associated.
  --account-id: list<int> # Filters tasks by the account to which they are associated.
  --current-state: list<string> # Filters tasks by their current state. Valid current_states include: ['scheduled', 'completed'].
  --task-type: list<string> # Filters tasks by their task type. Valid task_types include: ['call', 'email', 'general'].
  --time-interval-filter: string # Filters tasks by time interval. Valid time_intervals include: ['overdue', 'today', 'tomorrow', 'this_week', 'next_week'].
  --idempotency-key: string # Filters tasks by idempotency key.
  --locale: list<string> # Filters tasks by locale of the person to which they are associated.
  --sort-by: string # Key to sort on, must be one of: due_date, due_at. Defaults to due_date
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to ASC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "user_id" $user_id "csv") (serialize-qp "person_id" $person_id "csv") (serialize-qp "account_id" $account_id "csv") (serialize-qp "current_state" $current_state "csv") (serialize-qp "task_type" $task_type "csv") (serialize-qp "time_interval_filter" $time_interval_filter "scalar") (serialize-qp "idempotency_key" $idempotency_key "scalar") (serialize-qp "locale" $locale "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/tasks.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "user_id": $user_id, "person_id": $person_id, "account_id": $account_id, "current_state": $current_state, "task_type": $task_type, "time_interval_filter": $time_interval_filter, "idempotency_key": $idempotency_key, "locale": $locale, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Create a Task
#
# POST /v2/tasks.json
export def "tasks-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  current_state: string # Current state of the task, valid options are: scheduled
  --description: string # A description of the task recorded for person at completion time
  due_date: string # Date of when the Task is due, ISO-8601 date format required
  --idempotency-key: string # Establishes a unique identifier to prevent duplicates from being created
  person_id: string # ID of the person to be contacted
  --remind-at: string # Datetime of when the user will be reminded of the task, ISO-8601 datetime format required
  subject: string # Subject line of the task.
  task_type: string # Task type, valid options are: call, email, general
  user_id: int # ID of the user linked to the task
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tasks.json")
  let req_body = {"current_state": $current_state, "description": $description, "due_date": $due_date, "idempotency_key": $idempotency_key, "person_id": $person_id, "remind_at": $remind_at, "subject": $subject, "task_type": $task_type, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch a task
#
# GET /v2/tasks/{id}.json
export def "tasks get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/tasks/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Task
#
# PUT /v2/tasks/{id}.json
export def "tasks update" [
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
  --current-state: string # Current state of the task, valid options are: completed
  --description: string # A description of the task recorded for person at completion time
  --due-date: string # Date of when the Task is due, ISO-8601 date format required
  --is-logged: oneof<nothing, bool> # A flag to indicate that the task should only be logged
  --remind-at: string # Datetime of when the user will be reminded of the task, ISO-8601 datetime format required
  --subject: string # Subject line of the task
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/tasks/{id}.json"))
  let req_body = {"current_state": $current_state, "description": $description, "due_date": $due_date, "is_logged": $is_logged, "remind_at": $remind_at, "subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch current team
#
# GET /v2/team.json
export def "team-json get" [
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
  let full_url = (build-url $base "/v2/team.json")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List team template attachments
#
# GET /v2/team_template_attachments.json
export def "team-template-attachments-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of team template attachments to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --team-template-id: list<int> # Filters template attachments by team template IDs
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "team_template_id" $team_template_id "csv") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/team_template_attachments.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "team_template_id": $team_template_id, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# List team templates
#
# GET /v2/team_templates.json
export def "team-templates-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # IDs of team templates to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --search: string # Filters email templates by title or subject
  --tag-ids: list<int> # Filters email templates by tags applied to the template by tag ID, not to exceed 100 IDs
  --tag: list<string> # Filters team templates by tags applied to the template, not to exceed 100 tags
  --include-archived-templates: oneof<nothing, bool> # Filters email templates to include archived templates or not
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, last_used_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "updated_at" $updated_at "csv") (serialize-qp "search" $search "scalar") (serialize-qp "tag_ids" $tag_ids "csv") (serialize-qp "tag" $tag "csv") (serialize-qp "include_archived_templates" $include_archived_templates "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "limit_paging_counts" $limit_paging_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/team_templates.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "updated_at": $updated_at, "search": $search, "tag_ids": $tag_ids, "tag": $tag, "include_archived_templates": $include_archived_templates, "sort_by": $sort_by, "sort_direction": $sort_direction, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "limit_paging_counts": $limit_paging_counts} | compact), body: null}
}

# Fetch a team template
#
# GET /v2/team_templates/{id}.json
export def "team-templates get" [
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
  --include-signature: oneof<nothing, bool> # Optionally will return the templates with the current user's email signature
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_signature" $include_signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/team_templates/{id}.json") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_signature": $include_signature} | compact), body: null}
}

# Create a live feed item
#
# POST /v2/third_party_live_feed_items
export def "third-party-live-feed-items create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event_occurred_at: string # Equality filters that are applied to the event_occurred_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"keys":[{"description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gt","type":"iso8601 string"},{"description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gte","type":"iso8601 string"},{"description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lt","type":"iso8601 string"},{"description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lte","type":"iso8601 string"}],"type":"object"}
  idempotency_key: string # Uniquely provided string specific to this event. This should be a value which can't be duplicated between external systems, meaning that an id is not sufficient.
  message: string # The message that relates to the subject. This message should start with a lower-case past-tense verb and end with a period (e.g. "received a package."). When live feed items are displayed to users, the subject's name is concatenated with the message and a joining space. Only HTML tags with an "href" attribute are allowed. Other attributes and tags will be stripped.
  subject_id: int # The ID of the subject of the live feed item (i.e. the "person" id).
  subject_type: string # The type of the subject of the live feed item. Currently only "person" is supported.
  user_guid: string # The guid for the user that this live feed item should be shown to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/third_party_live_feed_items")
  let req_body = {"event_occurred_at": $event_occurred_at, "idempotency_key": $idempotency_key, "message": $message, "subject_id": $subject_id, "subject_type": $subject_type, "user_guid": $user_guid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List users
#
# GET /v2/users.json
export def "users-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of users to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --guid: list<string> # Filters list to only include guids
  --group-id: list<string> # Filters users by group_id. An additional value of "_is_null" can be passed to filter users that are not in a group
  --role-id: list<string> # Filters users by role_id
  --search: string # Space-separated list of keywords used to find case-insensitive substring matches against First Name, Last Name, or Email
  --active: oneof<nothing, bool> # Filters users based on active attribute. Defaults to not applied
  --visible-only: oneof<nothing, bool> # Defaults to true. When true, only shows users that are actionable based on the team's privacy settings. When false, shows all users on the team, even if you can't take action on that user. Deactivated users are also included when false.
  --per-page: int # How many users to show per page in the range [1, 100]. Defaults to 25. Results are only paginated if the page parameter is defined
  --page: int # The current page to fetch users from. Defaults to returning all users
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --has-crm-user: oneof<nothing, bool> # Filters users based on if they have a crm user mapped or not.
  --work-country: list<string> # Filters users based on assigned work_country.
  --sort-by: string # Key to sort on, must be one of: id, email, name, group, role. Defaults to id
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "guid" $guid "csv") (serialize-qp "group_id" $group_id "csv") (serialize-qp "role_id" $role_id "csv") (serialize-qp "search" $search "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "visible_only" $visible_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_paging_counts" $include_paging_counts "scalar") (serialize-qp "has_crm_user" $has_crm_user "scalar") (serialize-qp "work_country" $work_country "csv") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/users.json" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "guid": $guid, "group_id": $group_id, "role_id": $role_id, "search": $search, "active": $active, "visible_only": $visible_only, "per_page": $per_page, "page": $page, "include_paging_counts": $include_paging_counts, "has_crm_user": $has_crm_user, "work_country": $work_country, "sort_by": $sort_by, "sort_direction": $sort_direction} | compact), body: null}
}

# Fetch a user
#
# GET /v2/users/{id}.json
export def "users get" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/users/{id}.json"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List webhook subscriptions
#
# GET /v2/webhook_subscriptions
export def "webhook-subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Filters webhook subscriptions by whether is enabled or not.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/webhook_subscriptions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"enabled": $enabled} | compact), body: null}
}

# Create a webhook subscription
#
# POST /v2/webhook_subscriptions
export def "webhook-subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  callback_token: string # Any string to be used as a shared secret when subscription events are published. SalesLoft will send the value of this callback_token in the payload of each event so the receiver may verify it matches the original value. This ensures webhook events are being delivered by SalesLoft.
  callback_url: string # URL for your callback handler
  event_type: string # Type of event the subscription is for. Visit the "Event Types" section of the webhooks page to find a list of supported event types.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/webhook_subscriptions")
  let req_body = {"callback_token": $callback_token, "callback_url": $callback_url, "event_type": $event_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a webhook subscription
#
# DELETE /v2/webhook_subscriptions/{id}
export def "webhook-subscriptions delete" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/webhook_subscriptions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a webhook subscription
#
# GET /v2/webhook_subscriptions/{id}
export def "webhook-subscriptions get" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/webhook_subscriptions/{id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a webhook subscription
#
# PUT /v2/webhook_subscriptions/{id}
export def "webhook-subscriptions update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Enable or disable the webhook subscription
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/webhook_subscriptions/{id}"))
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}
