# Auto-generated client for opendatasoft v2.1.0
# Source: https://api.apis.guru/v2/specs/opendatasoft.com/2.1.0/swagger.json
# Auth: --token flag or $env.OPENDATASOFT_TOKEN

const BASE_URL = "https://public.opendatasoft.com/api/v2"
const DEFAULT_AUTH = "query-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENDATASOFT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-apikey" => { {headers: {}, query: $"apikey=($token_val)"} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://public.opendatasoft.com/api/v2"] }
def auth-scheme-completer [] { ["query-apikey" "basic"] }

# Completers for enum parameters
def delimiter-completer [] { ["," ";" "|"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "root get" } } | get name | first)
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

# API entry point  Provides links for: * catalog, your domain's list of datasets * opendatasoft, all datasets on the Opendatasoft network
#
# GET /
# operationId: getRoot
export def "root get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all pages from this portal.
#
# GET /pages
# operationId: getPages
export def "pages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: table<href: string, rel: string>, pages: table<links: list, page: record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A single page's metadata from this portal
#
# GET /pages/{slug}
# operationId: getPage
export def "pages get" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: table<href: string, rel: string>, page: record<description: string, slug: string, title: record<en: string, fr: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Source entry points  Provides links for the source's datasets and metadata.
#
# GET /{source}
# operationId: getSource
export def "catalog get" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($source)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# **Deprecated, use `/datasets` instead.**
#
# GET /{source}/aggregates
# operationId: aggregateDatasets
export def "aggregates aggregateDatasets" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --group-by: string # A group by expression defines a grouping function for an aggregation. It can be:  - a field name: group result by each value of this field  - a range function: group result by range  - a date function: group result by date It is possible to specify a custom name with the 'as name' notation. For instance: group_by='city_field as city'.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
]: nothing -> record<aggregations: list<record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/aggregates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of available datasets, each with their endpoints, paginated.  Links provided: * previous page * next page * last page * first page
#
# GET /{source}/datasets
# operationId: getDatasets
export def "datasets list" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --group-by: string # A group by expression defines a grouping function for an aggregation. It can be:  - a field name: group result by each value of this field  - a range function: group result by range  - a date function: group result by date It is possible to specify a custom name with the 'as name' notation. For instance: group_by='city_field as city'.
  --qp-sort: list # **Deprecated, use `order_by` instead.**  A list of field names, each possibly prefixed with a minus (-).  Sorts results according to the specified fields' values. By default, the sort is ascending (from the smallest value to the biggest value). A minus sign (‘-‘) may be used to perform a descending sort. Sorting is only available on numeric fields (int, double, date and datetime) and on text fields which have the sortable annotation.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --pretty: oneof<nothing, bool> # Activate pretty print (default: false)
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --include-app-metas: oneof<nothing, bool> # Explicitely request application metas for each datasets.  (default: false)
]: nothing -> record<datasets: table<dataset: record, links: list>, links: table<href: string, rel: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "pretty" $pretty "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "include_app_metas" $include_app_metas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of available endpoints for the specified dataset, with metadata and endpoints.  Will provide links for: * the attachments endpoint * the files endpoint * the records endpoint * the catalog endpoint
#
# GET /{source}/datasets/{dataset_id}
# operationId: getDataset
export def "datasets get" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --pretty: oneof<nothing, bool> # Activate pretty print (default: false)
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --include-app-metas: oneof<nothing, bool> # Explicitely request application metas for each datasets.  (default: false)
]: nothing -> record<dataset: record<attachments: list<record>, data_visible: bool, dataset_id: string, features: list<string>, fields: list<record>, has_records: bool, metas: record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "pretty" $pretty "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "include_app_metas" $include_app_metas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# **Deprecated, use `/records` instead.**
#
# GET /{source}/datasets/{dataset_id}/aggregates
# operationId: aggregateRecords
export def "datasets-aggregates aggregateRecords" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --group-by: string # A group by expression defines a grouping function for an aggregation. It can be:  - a field name: group result by each value of this field  - a range function: group result by range  - a date function: group result by date It is possible to specify a custom name with the 'as name' notation. For instance: group_by='city_field as city'.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
]: nothing -> record<aggregations: list<record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/aggregates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of all available attachments
#
# GET /{source}/datasets/{dataset_id}/attachments
# operationId: getDatasetAttachements
export def "datasets-attachments get" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: table<href: string, metas: record>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download attachment
#
# GET /{source}/datasets/{dataset_id}/attachments/{attachment_id}
# operationId: downloadDatasetAttachement
export def "datasets-attachments downloadDatasetAttachement" [
  source: string
  dataset_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/attachments/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export dataset in CSV format
#
# GET /{source}/datasets/{dataset_id}/exports/csv
# operationId: exportRecordsCSV
export def "datasets-exports-csv exportRecordsCSV" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --qp-sort: list # **Deprecated, use `order_by` instead.**  A list of field names, each possibly prefixed with a minus (-).  Sorts results according to the specified fields' values. By default, the sort is ascending (from the smallest value to the biggest value). A minus sign (‘-‘) may be used to perform a descending sort. Sorting is only available on numeric fields (int, double, date and datetime) and on text fields which have the sortable annotation.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return in export.  Use -1 (default) to retrieve all records  (default: -1)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --delimiter: string@delimiter-completer # Provide a different delimiter (default ','). (default: ;)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "delimiter" $delimiter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/exports/csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export dataset in GEOJSON format
#
# GET /{source}/datasets/{dataset_id}/exports/geojson
# operationId: exportRecordsGEOJSON
export def "datasets-exports-geojson exportRecordsGEOJSON" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --qp-sort: list # **Deprecated, use `order_by` instead.**  A list of field names, each possibly prefixed with a minus (-).  Sorts results according to the specified fields' values. By default, the sort is ascending (from the smallest value to the biggest value). A minus sign (‘-‘) may be used to perform a descending sort. Sorting is only available on numeric fields (int, double, date and datetime) and on text fields which have the sortable annotation.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return in export.  Use -1 (default) to retrieve all records  (default: -1)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --pretty: oneof<nothing, bool> # Activate pretty print (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "pretty" $pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/exports/geojson" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export dataset in ICAL format
#
# GET /{source}/datasets/{dataset_id}/exports/ical
# operationId: exportRecordsICAL
export def "datasets-exports-ical exportRecordsICAL" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --qp-sort: list # **Deprecated, use `order_by` instead.**  A list of field names, each possibly prefixed with a minus (-).  Sorts results according to the specified fields' values. By default, the sort is ascending (from the smallest value to the biggest value). A minus sign (‘-‘) may be used to perform a descending sort. Sorting is only available on numeric fields (int, double, date and datetime) and on text fields which have the sortable annotation.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return in export.  Use -1 (default) to retrieve all records  (default: -1)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/exports/ical" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export dataset in JSON format
#
# GET /{source}/datasets/{dataset_id}/exports/json
# operationId: exportRecordsJSON
export def "datasets-exports-json exportRecordsJSON" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --qp-sort: list # **Deprecated, use `order_by` instead.**  A list of field names, each possibly prefixed with a minus (-).  Sorts results according to the specified fields' values. By default, the sort is ascending (from the smallest value to the biggest value). A minus sign (‘-‘) may be used to perform a descending sort. Sorting is only available on numeric fields (int, double, date and datetime) and on text fields which have the sortable annotation.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return in export.  Use -1 (default) to retrieve all records  (default: -1)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --pretty: oneof<nothing, bool> # Activate pretty print (default: false)
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "pretty" $pretty "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/exports/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export dataset in OV2 format
#
# GET /{source}/datasets/{dataset_id}/exports/ov2
# operationId: exportRecordsOV2
export def "datasets-exports-ov2 exportRecordsOV2" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --qp-sort: list # **Deprecated, use `order_by` instead.**  A list of field names, each possibly prefixed with a minus (-).  Sorts results according to the specified fields' values. By default, the sort is ascending (from the smallest value to the biggest value). A minus sign (‘-‘) may be used to perform a descending sort. Sorting is only available on numeric fields (int, double, date and datetime) and on text fields which have the sortable annotation.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return in export.  Use -1 (default) to retrieve all records  (default: -1)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/exports/ov2" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export dataset in Esri shapefile (shp) format
#
# GET /{source}/datasets/{dataset_id}/exports/shp
# operationId: exportRecordsSHP
export def "datasets-exports-shp exportRecordsSHP" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --qp-sort: list # **Deprecated, use `order_by` instead.**  A list of field names, each possibly prefixed with a minus (-).  Sorts results according to the specified fields' values. By default, the sort is ascending (from the smallest value to the biggest value). A minus sign (‘-‘) may be used to perform a descending sort. Sorting is only available on numeric fields (int, double, date and datetime) and on text fields which have the sortable annotation.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return in export.  Use -1 (default) to retrieve all records  (default: -1)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/exports/shp" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export dataset in XLS (Excel) format
#
# GET /{source}/datasets/{dataset_id}/exports/xls
# operationId: exportRecordsXLS
export def "datasets-exports-xls exportRecordsXLS" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --qp-sort: list # **Deprecated, use `order_by` instead.**  A list of field names, each possibly prefixed with a minus (-).  Sorts results according to the specified fields' values. By default, the sort is ascending (from the smallest value to the biggest value). A minus sign (‘-‘) may be used to perform a descending sort. Sorting is only available on numeric fields (int, double, date and datetime) and on text fields which have the sortable annotation.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return in export.  Use -1 (default) to retrieve all records  (default: -1)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/exports/xls" $qp)
  let accept_val = "xls"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enumerate facets values for records and return a list of values for each facet. Can be used to implement guided navigation in large result sets.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#enumerating-facets-values) for more details.
#
# GET /{source}/datasets/{dataset_id}/facets
# operationId: getRecordsFacets
export def "datasets-facets get" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> record<facets: table<facets: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "search" $search "multi") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/facets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new feedback entry.
#
# PUT /{source}/datasets/{dataset_id}/feedback
# operationId: sendDatasetFeedback
export def "datasets-feedback sendDatasetFeedback" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --newValues: record # New record value
  --recordid: string # Feedback entry's recordid
  --schema: record # Record schema
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/feedback")
  let body = {comment: $comment, newValues: $newValues, recordid: $recordid, schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download file
#
# GET /{source}/datasets/{dataset_id}/files/{file_id}
# operationId: getDatasetFile
export def "datasets-files get" [
  source: string
  dataset_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --thumbnail-size: string # Set the size of the thumbnail representing the resource (attachment, image or file)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thumbnail_size" $thumbnail_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/files/($file_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search dataset's records.
#
# GET /{source}/datasets/{dataset_id}/records
# operationId: getRecords
export def "datasets-records list" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --group-by: string # A group by expression defines a grouping function for an aggregation. It can be:  - a field name: group result by each value of this field  - a range function: group result by range  - a date function: group result by date It is possible to specify a custom name with the 'as name' notation. For instance: group_by='city_field as city'.
  --qp-sort: list # **Deprecated, use `order_by` instead.**  A list of field names, each possibly prefixed with a minus (-).  Sorts results according to the specified fields' values. By default, the sort is ascending (from the smallest value to the biggest value). A minus sign (‘-‘) may be used to perform a descending sort. Sorting is only available on numeric fields (int, double, date and datetime) and on text fields which have the sortable annotation.
  --order-by: list # A comma-separated list of field names or aggregations to sort on, followed by an order (`asc` or `desc`).  Sorts results according to the specified fields' values in ascending order by default. To sort results in descending order, use the `desc` keyword.  Example: `sum(age) desc, name asc`
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --pretty: oneof<nothing, bool> # Activate pretty print (default: false)
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> record<links: table<href: string, rel: string>, records: table<links: list, record: record>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "where" $qp_where "multi") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "order_by" $order_by "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "pretty" $pretty "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single record based on its ID.
#
# GET /{source}/datasets/{dataset_id}/records/{record_id}
# operationId: getRecord
export def "datasets-records get" [
  source: string
  dataset_id: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # A select expression can be used to add, remove or change fields to return. An expression can be:   - a wildcard ('*'): return all fields   - a field name: return only this field   - an include/exclude function. Include (resp exclude) all field matching include/exclude expression. This expression can contain wildcard. For example: include(spa*) will return all fields begining with 'spa'   - a complex expression: return the result of this expression. A label can be set for this expression, in that case, field will be named with this label. For instance: 'size * 2 as bigger_size' will return a new field named bigger_size and containing the double of size field value.
  --pretty: oneof<nothing, bool> # Activate pretty print (default: false)
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> record<links: table<href: string, rel: string>, record: record<fields: record, id: string, size: int, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "pretty" $pretty "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/records/($record_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of reuses
#
# GET /{source}/datasets/{dataset_id}/reuses
# operationId: getDatasetReuses
export def "datasets-reuses list" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> record<links: table<href: string, rel: string>, reuses: table<created_at: string, description: any, id: string, thumbnail: string, title: string, url: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/reuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single reuse based on its ID.
#
# GET /{source}/datasets/{dataset_id}/reuses/{reuse_id}
# operationId: getDatasetReuse
export def "datasets-reuses get" [
  source: string
  dataset_id: string
  reuse_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> record<links: table<href: string, rel: string>, reuse: record<created_at: string, description: any, id: string, thumbnail: string, title: string, url: string, user: record<first_name: string, last_name: string, username: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/reuses/($reuse_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all snapshots for this dataset.
#
# GET /{source}/datasets/{dataset_id}/snapshots
# operationId: getDatasetSnapshots
export def "datasets-snapshots get" [
  source: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> record<links: table<href: string, rel: string>, snapshots: table<created_at: string, description: string, href: string, snapshot_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all snapshots for this dataset.
#
# GET /{source}/datasets/{dataset_id}/snapshots/{snapshot_id}
# operationId: downloadDatasetSnapshot
export def "datasets-snapshots downloadDatasetSnapshot" [
  source: string
  dataset_id: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/datasets/($dataset_id)/snapshots/($snapshot_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export catalog (source) in CSV format
#
# GET /{source}/exports/csv
# operationId: exportDatasetsCSV
export def "exports-csv exportDatasetsCSV" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --include-app-metas: oneof<nothing, bool> # Explicitely request application metas for each datasets.  (default: false)
  --delimiter: string@delimiter-completer # Provide a different delimiter (default ','). (default: ;)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "include_app_metas" $include_app_metas "scalar") (serialize-qp "delimiter" $delimiter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/exports/csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export catalog (source) in JSON format
#
# GET /{source}/exports/json
# operationId: exportDatasetsJson
export def "exports-json exportDatasetsJson" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --pretty: oneof<nothing, bool> # Activate pretty print (default: false)
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --include-app-metas: oneof<nothing, bool> # Explicitely request application metas for each datasets.  (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "pretty" $pretty "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "include_app_metas" $include_app_metas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/exports/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export catalog (source) in RDF/XML format
#
# GET /{source}/exports/rdf
# operationId: exportDatasetsRDF
export def "exports-rdf exportDatasetsRDF" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --include-app-metas: oneof<nothing, bool> # Explicitely request application metas for each datasets.  (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "include_app_metas" $include_app_metas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/exports/rdf" $qp)
  let accept_val = "application/rdf+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export catalog (source) in RSS format
#
# GET /{source}/exports/rss
# operationId: exportDatasetsRSS
export def "exports-rss exportDatasetsRSS" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --include-app-metas: oneof<nothing, bool> # Explicitely request application metas for each datasets.  (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "include_app_metas" $include_app_metas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/exports/rss" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export catalog (source) in TTL (turtle/rdf) format
#
# GET /{source}/exports/ttl
# operationId: exportDatasetsTTL
export def "exports-ttl exportDatasetsTTL" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --include-app-metas: oneof<nothing, bool> # Explicitely request application metas for each datasets.  (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "include_app_metas" $include_app_metas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/exports/ttl" $qp)
  let accept_val = "text/turtle"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export catalog (source) in XLS (Excel) format
#
# GET /{source}/exports/xls
# operationId: exportDatasetsXLS
export def "exports-xls exportDatasetsXLS" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --limit: int # Number of items to return.  To use in conjonction with offset to implement pagination.  Limit maximum value is 100. To retrive more data use export entry points. The default value is 10.  (default: 10)
  --offset: int # Index of the first item to return (starting at 0).  To use in conjonction with limit to implement pagination.  (default: 0)
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --timezone: string # Set timezone for datetime fields (default: UTC)
  --include-app-metas: oneof<nothing, bool> # Explicitely request application metas for each datasets.  (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "multi") (serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "include_app_metas" $include_app_metas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/exports/xls" $qp)
  let accept_val = "xls"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enumerate facets values for datasets and return a list of values for each facet. Can be used to implement guided navigation in large result sets.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#enumerating-facets-values) for more details.
#
# GET /{source}/facets
# operationId: getDatasetsFacets
export def "facets get" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facet: list # A facet is a field used for simple filtering (through the parameters refine and exclude) or exploration (with the endpoint `/facets`).  Facets can be configured in the back-office or with this parameter.  Read [the facets documentation](https://help.opendatasoft.com/apis/ods-search-v2/#facets) for more details.
  --refine: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will only include the selected facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Refining with a facet is equivalent to selecting an entry in the left navigation panel.*  *refine is not available for monitoring sources*
  --exclude: list # An array of facet filters. For example **city:Paris** or **modified:2019/12**. The request will exclude the defined facet value.  Read [filtering with facets value](https://help.opendatasoft.com/apis/ods-search-v2/#filtering-with-facets-values) for more details.  *Not to be confused with a where filter. Excluding a facet value is equivalent to removing an entry in the left navigation panel.*  *exclude is not available for monitoring sources*
  --qp-where: list # An array of filters.  A filter is a text expression performing a simple full-text search that can also include logical operations (NOT, AND, OR...) as well as lots of other functions, thus performing more complex and more precise searches.  Read [the query language reference](https://docs.opendatasoft.com/api/explore/v2.html#where-clause) for more details.
  --search: list # An array of full text search.  A full text search performs a prefixed text search for each provided terms in all visible fields of a catalog/dataset.
  --timezone: string # Set timezone for datetime fields (default: UTC)
]: nothing -> record<facets: table<facets: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "facet" $facet "multi") (serialize-qp "refine" $refine "multi") (serialize-qp "exclude" $exclude "multi") (serialize-qp "where" $qp_where "multi") (serialize-qp "search" $search "multi") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($source)/facets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of available metadata templates types, each with their endpoints.
#
# GET /{source}/metadata_templates
# operationId: getMetadataTemplatesTypes
export def "metadata-templates get-by-source" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($source)/metadata_templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of metadata templates available for this type.
#
# GET /{source}/metadata_templates/{metadata_template_type}
# operationId: getMetadataTemplatesType
export def "metadata-templates get-by-source-metadata_template_type" [
  source: string
  metadata_template_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: table<href: string, rel: string>, metadata_templates: table<links: list, metadata_template: record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($source)/metadata_templates/($metadata_template_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A single metadata_template
#
# GET /{source}/metadata_templates/{metadata_template_type}/{metadata_template_name}
# operationId: getMetadataTemplate
export def "metadata-templates get-by-source-metadata_template_type-metadata_template_name" [
  source: string
  metadata_template_type: string
  metadata_template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: table<href: string, rel: string>, metadata_template: record<name: string, schema: list<record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($source)/metadata_templates/($metadata_template_type)/($metadata_template_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
