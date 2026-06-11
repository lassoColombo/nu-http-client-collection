# Auto-generated client for ENA Portal (Advance Search) API v0.0.0
# Source: https://www.ebi.ac.uk/ena/portal/api/api-docs?group=public
# Auth: --token flag or $env.ENA_PORTAL_ADVANCE_SEARCH__API_TOKEN

const BASE_URL = "http://localhost/ena/portal/api"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ENA_PORTAL_ADVANCE_SEARCH__API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://localhost/ena/portal/api"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def dataPortal-completer [] { ["ena" "faang" "metagenome" "pathogen"] }
def format-completer [] { ["json" "tsv"] }
def accept-completer [] { ["application/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "search search" } } | get name | first)
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

# Perform a warehouse search
#
# GET /search
# operationId: search
export def "search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-result: string # The result type (data set) to search against. Is mandatory.
  --qp-query: string # A set of search conditions joined by logical operators (AND, OR, NOT) and bound by double quotes. If none supplied, the full result set will be returned.
  --includeAccessionType: string # The connected data type to include accessions of
  --excludeAccessionType: string # The connected data type to exclude accessions of
  --includeAccessions: string # A list of accessions for records that you would like to be included with the results of your query
  --excludeAccessions: string # A list of accessions for records that you would like to be excluded from the results of your query
  --qp-fields: string # A list of fields (comma separated) to be returned in the result. If none supplied, the accession and description/title of the main result object will be returned.
  --limit: int # The maximum number of records to retrieve. This interface sets a limit of 10 for usability. Remove it for real use cases.If the full result set is to be fetched, the limit may be set to 0, or omitted. (default: 10)
  --dataPortal: string@dataPortal-completer # The data portal ID. Defaults to 'ena'.
  --dccDataOnly: string@bool-completer # Whether to limit the search to only DCC records. By default, all public data is also included in the search.
  --includeMetagenomes: string@bool-completer # Whether to include public metagenome data in the search. By default, these are not included. Note that any metagenome data associated with a DCC hub will always be included in a search against that DCC.
  --searchCurations: string@bool-completer # Search in curations.
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided. (default: tsv)
  --download: string@bool-completer # Whether to download the result as a file, rather than read it from the stream. By default, this is false. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "result" $qp_result "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "includeAccessionType" $includeAccessionType "scalar") (serialize-qp "excludeAccessionType" $excludeAccessionType "scalar") (serialize-qp "includeAccessions" $includeAccessions "scalar") (serialize-qp "excludeAccessions" $excludeAccessions "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "dataPortal" $dataPortal "scalar") (serialize-qp "dccDataOnly" $dccDataOnly "scalar") (serialize-qp "includeMetagenomes" $includeMetagenomes "scalar") (serialize-qp "searchCurations" $searchCurations "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "download" $download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform a warehouse search with POST
#
# POST /search
# operationId: searchPost
export def "search searchPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-result: string # The result type (data set) to search against. Is mandatory.
  --qp-query: string # A set of search conditions joined by logical operators (AND, OR, NOT) and bound by double quotes. If none supplied, the full result set will be returned.
  --includeAccessionType: string # The connected data type to include accessions of
  --excludeAccessionType: string # The connected data type to exclude accessions of
  --includeAccessions: string # A list of accessions for records that you would like to be included with the results of your query
  --excludeAccessions: string # A list of accessions for records that you would like to be excluded from the results of your query
  --qp-fields: string # A list of fields (comma separated) to be returned in the result. If none supplied, the accession and description/title of the main result object will be returned.
  --limit: int # The maximum number of records to retrieve. This interface sets a limit of 10 for usability. Remove it for real use cases.If the full result set is to be fetched, the limit may be set to 0, or omitted. (default: 10)
  --dataPortal: string@dataPortal-completer # The data portal ID. Defaults to 'ena'.
  --dccDataOnly: string@bool-completer # Whether to limit the search to only DCC records. By default, all public data is also included in the search. (default: false)
  --includeMetagenomes: string@bool-completer # Whether to include public metagenome data in the search. By default, these are not included. Note that any metagenome data associated with a DCC hub will always be included in a search against that DCC. (default: false)
  --searchCurations: string@bool-completer # Search in curations. (default: false)
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided. (default: tsv)
  --download: string@bool-completer # Whether to download the result as a file, rather than read it from the stream. By default, this is false. (default: false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "result" $qp_result "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "includeAccessionType" $includeAccessionType "scalar") (serialize-qp "excludeAccessionType" $excludeAccessionType "scalar") (serialize-qp "includeAccessions" $includeAccessions "scalar") (serialize-qp "excludeAccessions" $excludeAccessions "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "dataPortal" $dataPortal "scalar") (serialize-qp "dccDataOnly" $dccDataOnly "scalar") (serialize-qp "includeMetagenomes" $includeMetagenomes "scalar") (serialize-qp "searchCurations" $searchCurations "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "download" $download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Perform a search to get a script to download data files for the matched records.
#
# POST /files
# operationId: getDownloadFilesCommandsOrSize
export def "files post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-result: string # The result type (data set) to search against. Is mandatory.
  --body-query: string # A set of search conditions joined by logical operators (AND, OR, NOT) and bound by double quotes. If none supplied, the full result set will be returned.
  --field: string # The name of the file field to be downloaded.
  --limit: int # The maximum number of records to retrieve. This interface sets a limit of 10 for usability. Remove it for real use cases.If the full result set is to be fetched, the limit may be set to 0, or omitted. (default: 10)
  --dataPortal: string@dataPortal-completer # The data portal ID. Defaults to 'ena'.
  --files: list # A list of files
  --count: string@bool-completer # If true, returns only the total number and size of files. Default is false. Is ignored if the 'files' list is provided.
  --accession: string # Accession of record to get files for.
  --dccDataOnly: string@bool-completer # default: false
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let body = {result: $body_result, query: $body_query, field: $field, limit: $limit, dataPortal: $dataPortal, files: $files, count: $count, accession: $accession, dccDataOnly: $dccDataOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Count rows matching search parameters
#
# GET /count
# operationId: count
export def "count count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-result: string # The result type (data set) to search against. Is mandatory.
  --qp-query: string # A set of search conditions joined by logical operators (AND, OR, NOT) and bound by double quotes. If none supplied, the full result set will be returned.
  --includeAccessionType: string # The connected data type to include accessions of
  --excludeAccessionType: string # The connected data type to exclude accessions of
  --includeAccessions: string # A list of accessions for records that you would like to be included with the results of your query
  --excludeAccessions: string # A list of accessions for records that you would like to be excluded from the results of your query
  --dataPortal: string@dataPortal-completer # The data portal ID. Defaults to 'ena'.
  --dccDataOnly: string@bool-completer # Whether to limit the search to only DCC records. By default, all public data is also included in the search.
  --includeMetagenomes: string@bool-completer # Whether to include public metagenome data in the search. By default, these are not included. Note that any metagenome data associated with a DCC hub will always be included in a search against that DCC.
  --searchCurations: string@bool-completer # Search in curations.
  --field: string # The field to count values of. Only works on controlled value type fields.
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "result" $qp_result "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "includeAccessionType" $includeAccessionType "scalar") (serialize-qp "excludeAccessionType" $excludeAccessionType "scalar") (serialize-qp "includeAccessions" $includeAccessions "scalar") (serialize-qp "excludeAccessions" $excludeAccessions "scalar") (serialize-qp "dataPortal" $dataPortal "scalar") (serialize-qp "dccDataOnly" $dccDataOnly "scalar") (serialize-qp "includeMetagenomes" $includeMetagenomes "scalar") (serialize-qp "searchCurations" $searchCurations "scalar") (serialize-qp "field" $field "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count rows matching search parameters
#
# POST /count
# operationId: countPost
export def "count countPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-result: string # The result type (data set) to search against. Is mandatory.
  --qp-query: string # A set of search conditions joined by logical operators (AND, OR, NOT) and bound by double quotes. If none supplied, the full result set will be returned.
  --includeAccessionType: string # The connected data type to include accessions of
  --excludeAccessionType: string # The connected data type to exclude accessions of
  --includeAccessions: string # A list of accessions for records that you would like to be included with the results of your query
  --excludeAccessions: string # A list of accessions for records that you would like to be excluded from the results of your query
  --dataPortal: string@dataPortal-completer # The data portal ID. Defaults to 'ena'.
  --dccDataOnly: string@bool-completer # Whether to limit the search to only DCC records. By default, all public data is also included in the search. (default: false)
  --includeMetagenomes: string@bool-completer # Whether to include public metagenome data in the search. By default, these are not included. Note that any metagenome data associated with a DCC hub will always be included in a search against that DCC. (default: false)
  --searchCurations: string@bool-completer # Search in curations. (default: false)
  --field: string # The field to count values of. Only works on controlled value type fields.
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "result" $qp_result "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "includeAccessionType" $includeAccessionType "scalar") (serialize-qp "excludeAccessionType" $excludeAccessionType "scalar") (serialize-qp "includeAccessions" $includeAccessions "scalar") (serialize-qp "excludeAccessions" $excludeAccessions "scalar") (serialize-qp "dataPortal" $dataPortal "scalar") (serialize-qp "dccDataOnly" $dccDataOnly "scalar") (serialize-qp "includeMetagenomes" $includeMetagenomes "scalar") (serialize-qp "searchCurations" $searchCurations "scalar") (serialize-qp "field" $field "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/count" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of searchable fields for a result type.
#
# GET /searchFields
# operationId: getSearchFields
export def "search-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataPortal: string@dataPortal-completer # Data portal Id
  --qp-result: string # Result
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataPortal" $dataPortal "scalar") (serialize-qp "result" $qp_result "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/searchFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of fields that can be returned for a result type.
#
# GET /returnFields
# operationId: getReturnFields
export def "return-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataPortal: string@dataPortal-completer # Data portal Id
  --qp-result: string # Result
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataPortal" $dataPortal "scalar") (serialize-qp "result" $qp_result "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/returnFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of available result types (data sets) to search against.
#
# GET /results
# operationId: getResults
export def "results get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the relations for the given record to display in the UI.
#
# GET /relations/{dataClass}/{accession}
# operationId: getRelationByDataClassAndAccession
export def "relations get" [
  dataClass: string
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hopCount: int # Number of nodes to be traversed. (format: int32)
]: nothing -> record<nodes: table<acc: string, name: string, dataClass: string, root: bool>, links: table<source: string, sourceDataClass: string, target: string, targetDataClass: string, relation: string>, totalChildren: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hopCount" $hopCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/relations/($dataClass)/($accession)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the relations for the given taxon to display in the UI.
#
# GET /relations/TAXON/{accession}
# operationId: getTaxonHierarchyByAccession
export def "relations-taxon get" [
  accession: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ancestorLevel: int # Number of levels traverses up the taxonomy hierarchy. 0 to bring all the ancestors (format: int32)
  --childCount: int # Number of children to be retrieved. Use 0 to retrieve all the the children (format: int32)
]: nothing -> record<nodes: table<acc: string, name: string, dataClass: string, root: bool>, links: table<source: string, sourceDataClass: string, target: string, targetDataClass: string, relation: string>, totalChildren: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ancestorLevel" $ancestorLevel "scalar") (serialize-qp "childCount" $childCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/relations/TAXON/($accession)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the relations for the given taxon to display in the UI.
#
# GET /relations/taxon/{accession}
# operationId: getTaxonHierarchyByAccession_1
export def "relations-taxon get-by-accession" [
  accession: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ancestorLevel: int # Number of levels traverses up the taxonomy hierarchy. 0 to bring all the ancestors (format: int32)
  --childCount: int # Number of children to be retrieved. Use 0 to retrieve all the the children (format: int32)
]: nothing -> record<nodes: table<acc: string, name: string, dataClass: string, root: bool>, links: table<source: string, sourceDataClass: string, target: string, targetDataClass: string, relation: string>, totalChildren: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ancestorLevel" $ancestorLevel "scalar") (serialize-qp "childCount" $childCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/relations/taxon/($accession)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get links
#
# GET /links/{dataType}
# operationId: getLinks
export def "links get" [
  dataType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accession: string # Accession
  --qp-result: string # The result type of links.
  --limit: int # The maximum number of records to retrieve. This interface sets a limit of 10 for usability. Remove it for real use cases.If the full result set is to be fetched, the limit may be set to 0, or omitted. (default: 10)
  --subtree: string # Include subtree
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided. (default: tsv)
  --download: string@bool-completer # Whether to download the result as a file, rather than read it from the stream. By default, this is false. (default: false)
  --offset: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accession" $accession "scalar") (serialize-qp "result" $qp_result "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "subtree" $subtree "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "download" $download "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/links/($dataType)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get row count for file report from warehouse search
#
# GET /filereportcount
# operationId: fileReportCount
export def "filereportcount fileReportCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-result: string # The result type (data set) to search against. Is mandatory.
  --accession: string # Accession
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "result" $qp_result "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/filereportcount" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file report from warehouse search
#
# GET /filereport
# operationId: fileReport
export def "filereport fileReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-result: string # The result type (data set) to search against. Is mandatory.
  --accession: string # Accession
  --qp-fields: string # A list of fields (comma separated) to be returned in the result. If none supplied, the accession and ftp information for fastq,submitted and sra files will be returned.
  --limit: int # The maximum number of records to retrieve. This interface sets a limit of 10 for usability. Remove it for real use cases.If the full result set is to be fetched, the limit may be set to 0, or omitted. (default: 10)
  --format: string@format-completer # What format the results should be returned as: TSV (Tab Separated Values) or JSON. By default, a TSV report is provided.
  --download: string@bool-completer # Whether to download the result as a file, rather than read it from the stream. By default, this is false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "result" $qp_result "scalar") (serialize-qp "accession" $accession "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "download" $download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/filereport" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download the documentation as a PDF file.
#
# GET /doc
# operationId: downloadDoc
export def "doc downloadDoc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/doc")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of available values for a controlled vocabulary field.
#
# GET /controlledVocab
# operationId: getControlledVocab
export def "controlled-vocab get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --field: string # Field name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "field" $field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/controlledVocab" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of accession types that can be used in the search query.
#
# GET /accessionTypes
# operationId: getAccessionTypes
export def "accession-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-result: string # Result
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "result" $qp_result "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accessionTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
