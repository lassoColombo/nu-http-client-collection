# Auto-generated client for SearchServiceClient v2019-05-06-Preview
# Source: https://api.apis.guru/v2/specs/azure.com/search-searchservice/2019-05-06-Preview/swagger.json
# Auth: --token flag or $env.SEARCHSERVICECLIENT_TOKEN

const BASE_URL = "https://{searchServiceName}.search.windows.net"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEARCHSERVICECLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://{searchServiceName}.search.windows.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["azureblob" "azuresql" "azuretable" "cosmosdb" "mysql"] }
def prefer-completer [] { ["return=representation"] }
def analyzer-completer [] { ["ar.lucene" "ar.microsoft" "bg.lucene" "bg.microsoft" "bn.microsoft" "ca.lucene" "ca.microsoft" "cs.lucene" "cs.microsoft" "da.lucene" "da.microsoft" "de.lucene" "de.microsoft" "el.lucene" "el.microsoft" "en.lucene" "en.microsoft" "es.lucene" "es.microsoft" "et.microsoft" "eu.lucene" "fa.lucene" "fi.lucene" "fi.microsoft" "fr.lucene" "fr.microsoft" "ga.lucene" "gl.lucene" "gu.microsoft" "he.microsoft" "hi.lucene" "hi.microsoft" "hr.microsoft" "hu.lucene" "hu.microsoft" "hy.lucene" "id.lucene" "id.microsoft" "is.microsoft" "it.lucene" "it.microsoft" "ja.lucene" "ja.microsoft" "keyword" "kn.microsoft" "ko.lucene" "ko.microsoft" "lt.microsoft" "lv.lucene" "lv.microsoft" "ml.microsoft" "mr.microsoft" "ms.microsoft" "nb.microsoft" "nl.lucene" "nl.microsoft" "no.lucene" "pa.microsoft" "pattern" "pl.lucene" "pl.microsoft" "pt-BR.lucene" "pt-BR.microsoft" "pt-PT.lucene" "pt-PT.microsoft" "ro.lucene" "ro.microsoft" "ru.lucene" "ru.microsoft" "simple" "sk.microsoft" "sl.microsoft" "sr-cyrillic.microsoft" "sr-latin.microsoft" "standard.lucene" "standardasciifolding.lucene" "stop" "sv.lucene" "sv.microsoft" "ta.microsoft" "te.microsoft" "th.lucene" "th.microsoft" "tr.lucene" "tr.microsoft" "uk.microsoft" "ur.microsoft" "vi.microsoft" "whitespace" "zh-Hans.lucene" "zh-Hans.microsoft" "zh-Hant.lucene" "zh-Hant.microsoft"] }
def tokenizer-completer [] { ["classic" "edgeNGram" "keyword_v2" "letter" "lowercase" "microsoft_language_stemming_tokenizer" "microsoft_language_tokenizer" "nGram" "path_hierarchy_v2" "pattern" "standard_v2" "uax_url_email" "whitespace"] }
def format-completer [] { ["solr"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "datasources list-data-sources" } } | get name | first)
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

# Lists all datasources available for a search service.
#
# GET /datasources
# Docs: https://docs.microsoft.com/rest/api/searchservice/List-Data-Sources
# operationId: DataSources_List
export def "datasources list-data-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the data sources to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<value: table<_odata_etag: string, container: record, credentials: record, dataChangeDetectionPolicy: record, dataDeletionDetectionPolicy: record, description: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datasources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "api-version": $api_version} | compact), body: null}
}

# Creates a new datasource.
#
# POST /datasources
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Data-Source
# operationId: DataSources_Create
# --container shape: {name: string, query?: string}
# --credentials shape: {connectionString?: string}
# --dataChangeDetectionPolicy shape: {@odata.type: string}
# --dataDeletionDetectionPolicy shape: {@odata.type: string}
export def "datasources create-data-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --odata-etag: string # The ETag of the DataSource.
  container: any # Represents information about the entity (such as Azure SQL table or CosmosDB collection) that will be indexed. — shape: {name: string, query?: string}
  credentials: any # Represents credentials that can be used to connect to a datasource. — shape: {connectionString?: string}
  --data-change-detection-policy: any # Abstract base class for data change detection policies. — shape: {@odata.type: string}
  --data-deletion-detection-policy: any # Abstract base class for data deletion detection policies. — shape: {@odata.type: string}
  --description: string # The description of the datasource.
  name: string # The name of the datasource.
  type: string@type-completer # Defines the type of a datasource.
]: any -> record<_odata_etag: string, container: record<name: string, query: string>, credentials: record<connectionString: string>, dataChangeDetectionPolicy: record<_odata_type: string>, dataDeletionDetectionPolicy: record<_odata_type: string>, description: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datasources" $qp)
  let req_body = {"@odata.etag": $odata_etag, "container": $container, "credentials": $credentials, "dataChangeDetectionPolicy": $data_change_detection_policy, "dataDeletionDetectionPolicy": $data_deletion_detection_policy, "description": $description, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a datasource.
#
# DELETE /datasources('{dataSourceName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Delete-Data-Source
# operationId: DataSources_Delete
export def "datasources delete-data-sources" [
  data_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($data_source_name | is-empty) { error make --unspanned { msg: "path parameter 'dataSourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_source_name: (encode-path-segment $data_source_name)} | format pattern "/datasources('{data_source_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Retrieves a datasource definition.
#
# GET /datasources('{dataSourceName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Data-Source
# operationId: DataSources_Get
export def "datasources get-data-sources" [
  data_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<_odata_etag: string, container: record<name: string, query: string>, credentials: record<connectionString: string>, dataChangeDetectionPolicy: record<_odata_type: string>, dataDeletionDetectionPolicy: record<_odata_type: string>, description: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($data_source_name | is-empty) { error make --unspanned { msg: "path parameter 'dataSourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_source_name: (encode-path-segment $data_source_name)} | format pattern "/datasources('{data_source_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates a new datasource or updates a datasource if it already exists.
#
# PUT /datasources('{dataSourceName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Update-Data-Source
# operationId: DataSources_CreateOrUpdate
# --container shape: {name: string, query?: string}
# --credentials shape: {connectionString?: string}
# --dataChangeDetectionPolicy shape: {@odata.type: string}
# --dataDeletionDetectionPolicy shape: {@odata.type: string}
export def "datasources create-data-sources-or-update" [
  data_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success.
  --odata-etag: string # The ETag of the DataSource.
  container: any # Represents information about the entity (such as Azure SQL table or CosmosDB collection) that will be indexed. — shape: {name: string, query?: string}
  credentials: any # Represents credentials that can be used to connect to a datasource. — shape: {connectionString?: string}
  --data-change-detection-policy: any # Abstract base class for data change detection policies. — shape: {@odata.type: string}
  --data-deletion-detection-policy: any # Abstract base class for data deletion detection policies. — shape: {@odata.type: string}
  --description: string # The description of the datasource.
  name: string # The name of the datasource.
  type: string@type-completer # Defines the type of a datasource.
]: any -> record<_odata_etag: string, container: record<name: string, query: string>, credentials: record<connectionString: string>, dataChangeDetectionPolicy: record<_odata_type: string>, dataDeletionDetectionPolicy: record<_odata_type: string>, description: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($data_source_name | is-empty) { error make --unspanned { msg: "path parameter 'dataSourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_source_name: (encode-path-segment $data_source_name)} | format pattern "/datasources('{data_source_name}')") $qp)
  let req_body = {"@odata.etag": $odata_etag, "container": $container, "credentials": $credentials, "dataChangeDetectionPolicy": $data_change_detection_policy, "dataDeletionDetectionPolicy": $data_deletion_detection_policy, "description": $description, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match, "Prefer": $prefer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all indexers available for a search service.
#
# GET /indexers
# Docs: https://docs.microsoft.com/rest/api/searchservice/List-Indexers
# operationId: Indexers_List
export def "indexers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the indexers to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<value: table<_odata_etag: string, dataSourceName: string, description: string, disabled: bool, fieldMappings: list, name: string, outputFieldMappings: list, parameters: record, schedule: record, skillsetName: string, targetIndexName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/indexers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "api-version": $api_version} | compact), body: null}
}

# Creates a new indexer.
#
# POST /indexers
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Indexer
# operationId: Indexers_Create
# --fieldMappings item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
# --outputFieldMappings item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
# --parameters shape: {base64EncodeKeys?: bool, batchSize?: int, configuration?: record, maxFailedItems?: int, maxFailedItemsPerBatch?: int}
# --schedule shape: {interval: string, startTime?: string}
export def "indexers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --odata-etag: string # The ETag of the Indexer.
  data_source_name: string # The name of the datasource from which this indexer reads data.
  --description: string # The description of the indexer.
  --disabled: oneof<nothing, bool> # A value indicating whether the indexer is disabled. Default is false. (default: false)
  --field-mappings: list # Defines mappings between fields in the data source and corresponding target fields in the index. — item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
  name: string # The name of the indexer.
  --output-field-mappings: list # Output field mappings are applied after enrichment and immediately before indexing. — item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
  --parameters: any # Represents parameters for indexer execution. — shape: {base64EncodeKeys?: bool, batchSize?: int, configuration?: record, maxFailedItems?: int, maxFailedItemsPerBatch?: int}
  --schedule: any # Represents a schedule for indexer execution. — shape: {interval: string, startTime?: string}
  --skillset-name: string # The name of the skillset executing with this indexer.
  target_index_name: string # The name of the index to which this indexer writes data.
]: any -> record<_odata_etag: string, dataSourceName: string, description: string, disabled: bool, fieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, name: string, outputFieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, parameters: record<base64EncodeKeys: bool, batchSize: int, configuration: record, maxFailedItems: int, maxFailedItemsPerBatch: int>, schedule: record<interval: string, startTime: string>, skillsetName: string, targetIndexName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/indexers" $qp)
  let req_body = {"@odata.etag": $odata_etag, "dataSourceName": $data_source_name, "description": $description, "disabled": $disabled, "fieldMappings": $field_mappings, "name": $name, "outputFieldMappings": $output_field_mappings, "parameters": $parameters, "schedule": $schedule, "skillsetName": $skillset_name, "targetIndexName": $target_index_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes an indexer.
#
# DELETE /indexers('{indexerName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Delete-Indexer
# operationId: Indexers_Delete
export def "indexers delete" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($indexer_name | is-empty) { error make --unspanned { msg: "path parameter 'indexerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({indexer_name: (encode-path-segment $indexer_name)} | format pattern "/indexers('{indexer_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Retrieves an indexer definition.
#
# GET /indexers('{indexerName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Indexer
# operationId: Indexers_Get
export def "indexers get" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<_odata_etag: string, dataSourceName: string, description: string, disabled: bool, fieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, name: string, outputFieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, parameters: record<base64EncodeKeys: bool, batchSize: int, configuration: record, maxFailedItems: int, maxFailedItemsPerBatch: int>, schedule: record<interval: string, startTime: string>, skillsetName: string, targetIndexName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($indexer_name | is-empty) { error make --unspanned { msg: "path parameter 'indexerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({indexer_name: (encode-path-segment $indexer_name)} | format pattern "/indexers('{indexer_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates a new indexer or updates an indexer if it already exists.
#
# PUT /indexers('{indexerName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Indexer
# operationId: Indexers_CreateOrUpdate
# --fieldMappings item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
# --outputFieldMappings item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
# --parameters shape: {base64EncodeKeys?: bool, batchSize?: int, configuration?: record, maxFailedItems?: int, maxFailedItemsPerBatch?: int}
# --schedule shape: {interval: string, startTime?: string}
export def "indexers create-or-update" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success.
  --odata-etag: string # The ETag of the Indexer.
  data_source_name: string # The name of the datasource from which this indexer reads data.
  --description: string # The description of the indexer.
  --disabled: oneof<nothing, bool> # A value indicating whether the indexer is disabled. Default is false. (default: false)
  --field-mappings: list # Defines mappings between fields in the data source and corresponding target fields in the index. — item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
  name: string # The name of the indexer.
  --output-field-mappings: list # Output field mappings are applied after enrichment and immediately before indexing. — item shape: {mappingFunction?: any, sourceFieldName: string, targetFieldName?: string}
  --parameters: any # Represents parameters for indexer execution. — shape: {base64EncodeKeys?: bool, batchSize?: int, configuration?: record, maxFailedItems?: int, maxFailedItemsPerBatch?: int}
  --schedule: any # Represents a schedule for indexer execution. — shape: {interval: string, startTime?: string}
  --skillset-name: string # The name of the skillset executing with this indexer.
  target_index_name: string # The name of the index to which this indexer writes data.
]: any -> record<_odata_etag: string, dataSourceName: string, description: string, disabled: bool, fieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, name: string, outputFieldMappings: table<mappingFunction: record, sourceFieldName: string, targetFieldName: string>, parameters: record<base64EncodeKeys: bool, batchSize: int, configuration: record, maxFailedItems: int, maxFailedItemsPerBatch: int>, schedule: record<interval: string, startTime: string>, skillsetName: string, targetIndexName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($indexer_name | is-empty) { error make --unspanned { msg: "path parameter 'indexerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({indexer_name: (encode-path-segment $indexer_name)} | format pattern "/indexers('{indexer_name}')") $qp)
  let req_body = {"@odata.etag": $odata_etag, "dataSourceName": $data_source_name, "description": $description, "disabled": $disabled, "fieldMappings": $field_mappings, "name": $name, "outputFieldMappings": $output_field_mappings, "parameters": $parameters, "schedule": $schedule, "skillsetName": $skillset_name, "targetIndexName": $target_index_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match, "Prefer": $prefer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Resets the change tracking state associated with an indexer.
#
# POST /indexers('{indexerName}')/search.reset
# Docs: https://docs.microsoft.com/rest/api/searchservice/Reset-Indexer
# operationId: Indexers_Reset
export def "indexers-search-reset reset" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($indexer_name | is-empty) { error make --unspanned { msg: "path parameter 'indexerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({indexer_name: (encode-path-segment $indexer_name)} | format pattern "/indexers('{indexer_name}')/search.reset") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Runs an indexer on-demand.
#
# POST /indexers('{indexerName}')/search.run
# Docs: https://docs.microsoft.com/rest/api/searchservice/Run-Indexer
# operationId: Indexers_Run
export def "indexers-search-run create" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($indexer_name | is-empty) { error make --unspanned { msg: "path parameter 'indexerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({indexer_name: (encode-path-segment $indexer_name)} | format pattern "/indexers('{indexer_name}')/search.run") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Returns the current status and execution history of an indexer.
#
# GET /indexers('{indexerName}')/search.status
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Indexer-Status
# operationId: Indexers_GetStatus
export def "indexers-search-status get" [
  indexer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<executionHistory: table<endTime: string, errorMessage: string, errors: list, finalTrackingState: string, initialTrackingState: string, itemsFailed: int, itemsProcessed: int, startTime: string, status: string, warnings: list>, lastResult: record<endTime: string, errorMessage: string, errors: list<record>, finalTrackingState: string, initialTrackingState: string, itemsFailed: int, itemsProcessed: int, startTime: string, status: string, warnings: list<record>>, limits: record<maxDocumentContentCharactersToExtract: float, maxDocumentExtractionSize: float, maxRunTime: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($indexer_name | is-empty) { error make --unspanned { msg: "path parameter 'indexerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({indexer_name: (encode-path-segment $indexer_name)} | format pattern "/indexers('{indexer_name}')/search.status") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists all indexes available for a search service.
#
# GET /indexes
# Docs: https://docs.microsoft.com/rest/api/searchservice/List-Indexes
# operationId: Indexes_List
export def "indexes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the index definitions to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<value: table<_odata_etag: string, analyzers: list, charFilters: list, corsOptions: record, defaultScoringProfile: string, encryptionKey: record, fields: list, name: string, scoringProfiles: list, suggesters: list, tokenFilters: list, tokenizers: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/indexes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "api-version": $api_version} | compact), body: null}
}

# Creates a new search index.
#
# POST /indexes
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Index
# operationId: Indexes_Create
# --analyzers item shape: {@odata.type: string, name: string}
# --charFilters item shape: {@odata.type: string, name: string}
# --corsOptions shape: {allowedOrigins: list<string>, maxAgeInSeconds?: int}
# --encryptionKey shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
# --fields item shape: {analyzer?: "ar.microsoft"|"ar.lucene"|"hy.lucene"|"bn.microsoft"|"eu.lucene"|"bg.microsoft"|"bg.lucene"|"ca.microsoft"|"ca.lucene"|"zh-Hans.microsoft"|"zh-Hans.lucene"|"zh-Hant.microsoft"|"zh-Hant.lucene"|"hr.microsoft"|"cs.microsoft"|"cs.lucene"|"da.microsoft"|"da.lucene"|"nl.microsoft"|"nl.lucene"|"en.microsoft"|"en.lucene"|"et.microsoft"|"fi.microsoft"|"fi.lucene"|"fr.microsoft"|"fr.lucene"|"gl.lucene"|"de.microsoft"|"de.lucene"|"el.microsoft"|"el.lucene"|"gu.microsoft"|"he.microsoft"|"hi.microsoft"|"hi.lucene"|"hu.microsoft"|"hu.lucene"|"is.microsoft"|"id.microsoft"|"id.lucene"|"ga.lucene"|"it.microsoft"|"it.lucene"|"ja.microsoft"|"ja.lucene"|"kn.microsoft"|"ko.microsoft"|"ko.lucene"|"lv.microsoft"|"lv.lucene"|"lt.microsoft"|"ml.microsoft"|"ms.microsoft"|"mr.microsoft"|"nb.microsoft"|"no.lucene"|"fa.lucene"|"pl.microsoft"|"pl.lucene"|"pt-BR.microsoft"|"pt-BR.lucene"|"pt-PT.microsoft"|"pt-PT.lucene"|"pa.microsoft"|"ro.microsoft"|"ro.lucene"|"ru.microsoft"|"ru.lucene"|"sr-cyrillic.microsoft"|"sr-latin.microsoft"|"sk.microsoft"|"sl.microsoft"|"es.microsoft"|"es.lucene"|"sv.microsoft"|"sv.lucene"|"ta.microsoft"|"te.microsoft"|"th.microsoft"|"th.lucene"|"tr.microsoft"|"tr.lucene"|"uk.microsoft"|"ur.microsoft"|"vi.microsoft"|"standard.lucene"|"standardasciifolding.lucene"|"keyword"|"pattern"|"simple"|"stop"|"whitespace", ... (12 more fields)}
# --scoringProfiles item shape: {functionAggregation?: "sum"|"average"|"minimum"|"maximum"|"firstMatching", functions?: list, name: string, text?: any}
# --suggesters item shape: {name: string, searchMode: "analyzingInfixMatching", sourceFields: list<string>}
# --tokenFilters item shape: {@odata.type: string, name: string}
# --tokenizers item shape: {@odata.type: string, name: string}
export def "indexes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --odata-etag: string # The ETag of the index.
  --analyzers: list # The analyzers for the index. — item shape: {@odata.type: string, name: string}
  --char-filters: list # The character filters for the index. — item shape: {@odata.type: string, name: string}
  --cors-options: any # Defines options to control Cross-Origin Resource Sharing (CORS) for an index. — shape: {allowedOrigins: list<string>, maxAgeInSeconds?: int}
  --default-scoring-profile: string # The name of the scoring profile to use if none is specified in the query. If this property is not set and no scoring profile is specified in the query, then default scoring (tf-idf) will be used.
  --encryption-key: any # A customer-managed encryption key in Azure Key Vault. Keys that you create and manage can be used to encrypt or decrypt data-at-rest in Azure Cognitive Search, such as indexes and synonym maps. — shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
  fields: list # The fields of the index. — item shape: {analyzer?: "ar.microsoft"|"ar.lucene"|"hy.lucene"|"bn.microsoft"|"eu.lucene"|"bg.microsoft"|"bg.lucene"|"ca.microsoft"|"ca.lucene"|"zh-Hans.microsoft"|"zh-Hans.lucene"|"zh-Hant.microsoft"|"zh-Hant.lucene"|"hr.microsoft"|"cs.microsoft"|"cs.lucene"|"da.microsoft"|"da.lucene"|"nl.microsoft"|"nl.lucene"|"en.microsoft"|"en.lucene"|"et.microsoft"|"fi.microsoft"|"fi.lucene"|"fr.microsoft"|"fr.lucene"|"gl.lucene"|"de.microsoft"|"de.lucene"|"el.microsoft"|"el.lucene"|"gu.microsoft"|"he.microsoft"|"hi.microsoft"|"hi.lucene"|"hu.microsoft"|"hu.lucene"|"is.microsoft"|"id.microsoft"|"id.lucene"|"ga.lucene"|"it.microsoft"|"it.lucene"|"ja.microsoft"|"ja.lucene"|"kn.microsoft"|"ko.microsoft"|"ko.lucene"|"lv.microsoft"|"lv.lucene"|"lt.microsoft"|"ml.microsoft"|"ms.microsoft"|"mr.microsoft"|"nb.microsoft"|"no.lucene"|"fa.lucene"|"pl.microsoft"|"pl.lucene"|"pt-BR.microsoft"|"pt-BR.lucene"|"pt-PT.microsoft"|"pt-PT.lucene"|"pa.microsoft"|"ro.microsoft"|"ro.lucene"|"ru.microsoft"|"ru.lucene"|"sr-cyrillic.microsoft"|"sr-latin.microsoft"|"sk.microsoft"|"sl.microsoft"|"es.microsoft"|"es.lucene"|"sv.microsoft"|"sv.lucene"|"ta.microsoft"|"te.microsoft"|"th.microsoft"|"th.lucene"|"tr.microsoft"|"tr.lucene"|"uk.microsoft"|"ur.microsoft"|"vi.microsoft"|"standard.lucene"|"standardasciifolding.lucene"|"keyword"|"pattern"|"simple"|"stop"|"whitespace", ... (12 more fields)}
  name: string # The name of the index.
  --scoring-profiles: list # The scoring profiles for the index. — item shape: {functionAggregation?: "sum"|"average"|"minimum"|"maximum"|"firstMatching", functions?: list, name: string, text?: any}
  --suggesters: list # The suggesters for the index. — item shape: {name: string, searchMode: "analyzingInfixMatching", sourceFields: list<string>}
  --token-filters: list # The token filters for the index. — item shape: {@odata.type: string, name: string}
  --tokenizers: list # The tokenizers for the index. — item shape: {@odata.type: string, name: string}
]: any -> record<_odata_etag: string, analyzers: table<_odata_type: string, name: string>, charFilters: table<_odata_type: string, name: string>, corsOptions: record<allowedOrigins: list<string>, maxAgeInSeconds: int>, defaultScoringProfile: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, fields: table<analyzer: string, facetable: bool, fields: list, filterable: bool, indexAnalyzer: string, key: bool, name: string, retrievable: bool, searchAnalyzer: string, searchable: bool, sortable: bool, synonymMaps: list, type: string>, name: string, scoringProfiles: table<functionAggregation: string, functions: list, name: string, text: record>, suggesters: table<name: string, searchMode: string, sourceFields: list>, tokenFilters: table<_odata_type: string, name: string>, tokenizers: table<_odata_type: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/indexes" $qp)
  let req_body = {"@odata.etag": $odata_etag, "analyzers": $analyzers, "charFilters": $char_filters, "corsOptions": $cors_options, "defaultScoringProfile": $default_scoring_profile, "encryptionKey": $encryption_key, "fields": $fields, "name": $name, "scoringProfiles": $scoring_profiles, "suggesters": $suggesters, "tokenFilters": $token_filters, "tokenizers": $tokenizers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a search index and all the documents it contains.
#
# DELETE /indexes('{indexName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Delete-Index
# operationId: Indexes_Delete
export def "indexes delete" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'indexName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/indexes('{index_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Retrieves an index definition.
#
# GET /indexes('{indexName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Index
# operationId: Indexes_Get
export def "indexes get" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<_odata_etag: string, analyzers: table<_odata_type: string, name: string>, charFilters: table<_odata_type: string, name: string>, corsOptions: record<allowedOrigins: list<string>, maxAgeInSeconds: int>, defaultScoringProfile: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, fields: table<analyzer: string, facetable: bool, fields: list, filterable: bool, indexAnalyzer: string, key: bool, name: string, retrievable: bool, searchAnalyzer: string, searchable: bool, sortable: bool, synonymMaps: list, type: string>, name: string, scoringProfiles: table<functionAggregation: string, functions: list, name: string, text: record>, suggesters: table<name: string, searchMode: string, sourceFields: list>, tokenFilters: table<_odata_type: string, name: string>, tokenizers: table<_odata_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'indexName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/indexes('{index_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates a new search index or updates an index if it already exists.
#
# PUT /indexes('{indexName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Update-Index
# operationId: Indexes_CreateOrUpdate
# --analyzers item shape: {@odata.type: string, name: string}
# --charFilters item shape: {@odata.type: string, name: string}
# --corsOptions shape: {allowedOrigins: list<string>, maxAgeInSeconds?: int}
# --encryptionKey shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
# --fields item shape: {analyzer?: "ar.microsoft"|"ar.lucene"|"hy.lucene"|"bn.microsoft"|"eu.lucene"|"bg.microsoft"|"bg.lucene"|"ca.microsoft"|"ca.lucene"|"zh-Hans.microsoft"|"zh-Hans.lucene"|"zh-Hant.microsoft"|"zh-Hant.lucene"|"hr.microsoft"|"cs.microsoft"|"cs.lucene"|"da.microsoft"|"da.lucene"|"nl.microsoft"|"nl.lucene"|"en.microsoft"|"en.lucene"|"et.microsoft"|"fi.microsoft"|"fi.lucene"|"fr.microsoft"|"fr.lucene"|"gl.lucene"|"de.microsoft"|"de.lucene"|"el.microsoft"|"el.lucene"|"gu.microsoft"|"he.microsoft"|"hi.microsoft"|"hi.lucene"|"hu.microsoft"|"hu.lucene"|"is.microsoft"|"id.microsoft"|"id.lucene"|"ga.lucene"|"it.microsoft"|"it.lucene"|"ja.microsoft"|"ja.lucene"|"kn.microsoft"|"ko.microsoft"|"ko.lucene"|"lv.microsoft"|"lv.lucene"|"lt.microsoft"|"ml.microsoft"|"ms.microsoft"|"mr.microsoft"|"nb.microsoft"|"no.lucene"|"fa.lucene"|"pl.microsoft"|"pl.lucene"|"pt-BR.microsoft"|"pt-BR.lucene"|"pt-PT.microsoft"|"pt-PT.lucene"|"pa.microsoft"|"ro.microsoft"|"ro.lucene"|"ru.microsoft"|"ru.lucene"|"sr-cyrillic.microsoft"|"sr-latin.microsoft"|"sk.microsoft"|"sl.microsoft"|"es.microsoft"|"es.lucene"|"sv.microsoft"|"sv.lucene"|"ta.microsoft"|"te.microsoft"|"th.microsoft"|"th.lucene"|"tr.microsoft"|"tr.lucene"|"uk.microsoft"|"ur.microsoft"|"vi.microsoft"|"standard.lucene"|"standardasciifolding.lucene"|"keyword"|"pattern"|"simple"|"stop"|"whitespace", ... (12 more fields)}
# --scoringProfiles item shape: {functionAggregation?: "sum"|"average"|"minimum"|"maximum"|"firstMatching", functions?: list, name: string, text?: any}
# --suggesters item shape: {name: string, searchMode: "analyzingInfixMatching", sourceFields: list<string>}
# --tokenFilters item shape: {@odata.type: string, name: string}
# --tokenizers item shape: {@odata.type: string, name: string}
export def "indexes create-or-update" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-index-downtime: oneof<nothing, bool> # Allows new analyzers, tokenizers, token filters, or char filters to be added to an index by taking the index offline for at least a few seconds. This temporarily causes indexing and query requests to fail. Performance and write availability of the index can be impaired for several minutes after the index is updated, or longer for very large indexes.
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success.
  --odata-etag: string # The ETag of the index.
  --analyzers: list # The analyzers for the index. — item shape: {@odata.type: string, name: string}
  --char-filters: list # The character filters for the index. — item shape: {@odata.type: string, name: string}
  --cors-options: any # Defines options to control Cross-Origin Resource Sharing (CORS) for an index. — shape: {allowedOrigins: list<string>, maxAgeInSeconds?: int}
  --default-scoring-profile: string # The name of the scoring profile to use if none is specified in the query. If this property is not set and no scoring profile is specified in the query, then default scoring (tf-idf) will be used.
  --encryption-key: any # A customer-managed encryption key in Azure Key Vault. Keys that you create and manage can be used to encrypt or decrypt data-at-rest in Azure Cognitive Search, such as indexes and synonym maps. — shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
  fields: list # The fields of the index. — item shape: {analyzer?: "ar.microsoft"|"ar.lucene"|"hy.lucene"|"bn.microsoft"|"eu.lucene"|"bg.microsoft"|"bg.lucene"|"ca.microsoft"|"ca.lucene"|"zh-Hans.microsoft"|"zh-Hans.lucene"|"zh-Hant.microsoft"|"zh-Hant.lucene"|"hr.microsoft"|"cs.microsoft"|"cs.lucene"|"da.microsoft"|"da.lucene"|"nl.microsoft"|"nl.lucene"|"en.microsoft"|"en.lucene"|"et.microsoft"|"fi.microsoft"|"fi.lucene"|"fr.microsoft"|"fr.lucene"|"gl.lucene"|"de.microsoft"|"de.lucene"|"el.microsoft"|"el.lucene"|"gu.microsoft"|"he.microsoft"|"hi.microsoft"|"hi.lucene"|"hu.microsoft"|"hu.lucene"|"is.microsoft"|"id.microsoft"|"id.lucene"|"ga.lucene"|"it.microsoft"|"it.lucene"|"ja.microsoft"|"ja.lucene"|"kn.microsoft"|"ko.microsoft"|"ko.lucene"|"lv.microsoft"|"lv.lucene"|"lt.microsoft"|"ml.microsoft"|"ms.microsoft"|"mr.microsoft"|"nb.microsoft"|"no.lucene"|"fa.lucene"|"pl.microsoft"|"pl.lucene"|"pt-BR.microsoft"|"pt-BR.lucene"|"pt-PT.microsoft"|"pt-PT.lucene"|"pa.microsoft"|"ro.microsoft"|"ro.lucene"|"ru.microsoft"|"ru.lucene"|"sr-cyrillic.microsoft"|"sr-latin.microsoft"|"sk.microsoft"|"sl.microsoft"|"es.microsoft"|"es.lucene"|"sv.microsoft"|"sv.lucene"|"ta.microsoft"|"te.microsoft"|"th.microsoft"|"th.lucene"|"tr.microsoft"|"tr.lucene"|"uk.microsoft"|"ur.microsoft"|"vi.microsoft"|"standard.lucene"|"standardasciifolding.lucene"|"keyword"|"pattern"|"simple"|"stop"|"whitespace", ... (12 more fields)}
  name: string # The name of the index.
  --scoring-profiles: list # The scoring profiles for the index. — item shape: {functionAggregation?: "sum"|"average"|"minimum"|"maximum"|"firstMatching", functions?: list, name: string, text?: any}
  --suggesters: list # The suggesters for the index. — item shape: {name: string, searchMode: "analyzingInfixMatching", sourceFields: list<string>}
  --token-filters: list # The token filters for the index. — item shape: {@odata.type: string, name: string}
  --tokenizers: list # The tokenizers for the index. — item shape: {@odata.type: string, name: string}
]: any -> record<_odata_etag: string, analyzers: table<_odata_type: string, name: string>, charFilters: table<_odata_type: string, name: string>, corsOptions: record<allowedOrigins: list<string>, maxAgeInSeconds: int>, defaultScoringProfile: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, fields: table<analyzer: string, facetable: bool, fields: list, filterable: bool, indexAnalyzer: string, key: bool, name: string, retrievable: bool, searchAnalyzer: string, searchable: bool, sortable: bool, synonymMaps: list, type: string>, name: string, scoringProfiles: table<functionAggregation: string, functions: list, name: string, text: record>, suggesters: table<name: string, searchMode: string, sourceFields: list>, tokenFilters: table<_odata_type: string, name: string>, tokenizers: table<_odata_type: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'indexName' must be non-empty" } }
  let qp = [(serialize-qp "allowIndexDowntime" $allow_index_downtime "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/indexes('{index_name}')") $qp)
  let req_body = {"@odata.etag": $odata_etag, "analyzers": $analyzers, "charFilters": $char_filters, "corsOptions": $cors_options, "defaultScoringProfile": $default_scoring_profile, "encryptionKey": $encryption_key, "fields": $fields, "name": $name, "scoringProfiles": $scoring_profiles, "suggesters": $suggesters, "tokenFilters": $token_filters, "tokenizers": $tokenizers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match, "Prefer": $prefer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"allowIndexDowntime": $allow_index_downtime, "api-version": $api_version} | compact), body: $req_body}
}

# Shows how an analyzer breaks text into tokens.
#
# POST /indexes('{indexName}')/search.analyze
# Docs: https://docs.microsoft.com/rest/api/searchservice/test-analyzer
# operationId: Indexes_Analyze
export def "indexes-search-analyze create" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --analyzer: string@analyzer-completer # Defines the names of all text analyzers supported by Azure Cognitive Search.
  --char-filters: list<string> # An optional list of character filters to use when breaking the given text. This parameter can only be set when using the tokenizer parameter.
  text: string # The text to break into tokens.
  --token-filters: list<string> # An optional list of token filters to use when breaking the given text. This parameter can only be set when using the tokenizer parameter.
  --tokenizer: string@tokenizer-completer # Defines the names of all tokenizers supported by Azure Cognitive Search.
]: any -> record<tokens: table<endOffset: int, position: int, startOffset: int, token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'indexName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/indexes('{index_name}')/search.analyze") $qp)
  let req_body = {"analyzer": $analyzer, "charFilters": $char_filters, "text": $text, "tokenFilters": $token_filters, "tokenizer": $tokenizer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Returns statistics for the given index, including a document count and storage usage.
#
# GET /indexes('{indexName}')/search.stats
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Index-Statistics
# operationId: Indexes_GetStatistics
export def "indexes-search-stats get-statistics" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<documentCount: int, storageSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'indexName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/indexes('{index_name}')/search.stats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets service level statistics for a search service.
#
# GET /servicestats
# operationId: GetServiceStatistics
export def "servicestats get-service-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<counters: record<dataSourcesCount: record<quota: int, usage: int>, documentCount: record<quota: int, usage: int>, indexersCount: record<quota: int, usage: int>, indexesCount: record<quota: int, usage: int>, storageSize: record<quota: int, usage: int>, synonymMaps: record<quota: int, usage: int>>, limits: record<maxComplexCollectionFieldsPerIndex: int, maxComplexObjectsInCollectionsPerDocument: int, maxFieldNestingDepthPerIndex: int, maxFieldsPerIndex: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/servicestats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# List all skillsets in a search service.
#
# GET /skillsets
# Docs: https://docs.microsoft.com/rest/api/searchservice/list-skillset
# operationId: Skillsets_List
export def "skillsets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the skillsets to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<value: table<_odata_etag: string, cognitiveServices: record, description: string, name: string, skills: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/skillsets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "api-version": $api_version} | compact), body: null}
}

# Creates a new skillset in a search service.
#
# POST /skillsets
# Docs: https://docs.microsoft.com/rest/api/searchservice/create-skillset
# operationId: Skillsets_Create
# --cognitiveServices shape: {@odata.type: string, description?: string}
# --skills item shape: {@odata.type: string, context?: string, description?: string, inputs: list, name?: string, outputs: list}
export def "skillsets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --odata-etag: string # The ETag of the skillset.
  --cognitive-services: any # Abstract base class for describing any cognitive service resource attached to the skillset. — shape: {@odata.type: string, description?: string}
  description: string # The description of the skillset.
  name: string # The name of the skillset.
  skills: list # A list of skills in the skillset. — item shape: {@odata.type: string, context?: string, description?: string, inputs: list, name?: string, outputs: list}
]: any -> record<_odata_etag: string, cognitiveServices: record<_odata_type: string, description: string>, description: string, name: string, skills: table<_odata_type: string, context: string, description: string, inputs: list, name: string, outputs: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/skillsets" $qp)
  let req_body = {"@odata.etag": $odata_etag, "cognitiveServices": $cognitive_services, "description": $description, "name": $name, "skills": $skills} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a skillset in a search service.
#
# DELETE /skillsets('{skillsetName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/delete-skillset
# operationId: Skillsets_Delete
export def "skillsets delete" [
  skillset_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($skillset_name | is-empty) { error make --unspanned { msg: "path parameter 'skillsetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({skillset_name: (encode-path-segment $skillset_name)} | format pattern "/skillsets('{skillset_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Retrieves a skillset in a search service.
#
# GET /skillsets('{skillsetName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/get-skillset
# operationId: Skillsets_Get
export def "skillsets get" [
  skillset_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<_odata_etag: string, cognitiveServices: record<_odata_type: string, description: string>, description: string, name: string, skills: table<_odata_type: string, context: string, description: string, inputs: list, name: string, outputs: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($skillset_name | is-empty) { error make --unspanned { msg: "path parameter 'skillsetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({skillset_name: (encode-path-segment $skillset_name)} | format pattern "/skillsets('{skillset_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates a new skillset in a search service or updates the skillset if it already exists.
#
# PUT /skillsets('{skillsetName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/update-skillset
# operationId: Skillsets_CreateOrUpdate
# --cognitiveServices shape: {@odata.type: string, description?: string}
# --skills item shape: {@odata.type: string, context?: string, description?: string, inputs: list, name?: string, outputs: list}
export def "skillsets create-or-update" [
  skillset_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success.
  --odata-etag: string # The ETag of the skillset.
  --cognitive-services: any # Abstract base class for describing any cognitive service resource attached to the skillset. — shape: {@odata.type: string, description?: string}
  description: string # The description of the skillset.
  name: string # The name of the skillset.
  skills: list # A list of skills in the skillset. — item shape: {@odata.type: string, context?: string, description?: string, inputs: list, name?: string, outputs: list}
]: any -> record<_odata_etag: string, cognitiveServices: record<_odata_type: string, description: string>, description: string, name: string, skills: table<_odata_type: string, context: string, description: string, inputs: list, name: string, outputs: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($skillset_name | is-empty) { error make --unspanned { msg: "path parameter 'skillsetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({skillset_name: (encode-path-segment $skillset_name)} | format pattern "/skillsets('{skillset_name}')") $qp)
  let req_body = {"@odata.etag": $odata_etag, "cognitiveServices": $cognitive_services, "description": $description, "name": $name, "skills": $skills} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match, "Prefer": $prefer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all synonym maps available for a search service.
#
# GET /synonymmaps
# Docs: https://docs.microsoft.com/rest/api/searchservice/List-Synonym-Maps
# operationId: SynonymMaps_List
export def "synonymmaps list-synonym-maps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # Selects which top-level properties of the synonym maps to retrieve. Specified as a comma-separated list of JSON property names, or '*' for all properties. The default is all properties.
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<value: table<_odata_etag: string, encryptionKey: record, format: string, name: string, synonyms: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/synonymmaps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "api-version": $api_version} | compact), body: null}
}

# Creates a new synonym map.
#
# POST /synonymmaps
# Docs: https://docs.microsoft.com/rest/api/searchservice/Create-Synonym-Map
# operationId: SynonymMaps_Create
# --encryptionKey shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
export def "synonymmaps create-synonym-maps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --odata-etag: string # The ETag of the synonym map.
  --encryption-key: any # A customer-managed encryption key in Azure Key Vault. Keys that you create and manage can be used to encrypt or decrypt data-at-rest in Azure Cognitive Search, such as indexes and synonym maps. — shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
  format: string@format-completer # The format of the synonym map. Only the 'solr' format is currently supported.
  name: string # The name of the synonym map.
  synonyms: string # A series of synonym rules in the specified synonym map format. The rules must be separated by newlines.
]: any -> record<_odata_etag: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, format: string, name: string, synonyms: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/synonymmaps" $qp)
  let req_body = {"@odata.etag": $odata_etag, "encryptionKey": $encryption_key, "format": $format, "name": $name, "synonyms": $synonyms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a synonym map.
#
# DELETE /synonymmaps('{synonymMapName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Delete-Synonym-Map
# operationId: SynonymMaps_Delete
export def "synonymmaps delete-synonym-maps" [
  synonym_map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($synonym_map_name | is-empty) { error make --unspanned { msg: "path parameter 'synonymMapName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({synonym_map_name: (encode-path-segment $synonym_map_name)} | format pattern "/synonymmaps('{synonym_map_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Retrieves a synonym map definition.
#
# GET /synonymmaps('{synonymMapName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Get-Synonym-Map
# operationId: SynonymMaps_Get
export def "synonymmaps get-synonym-maps" [
  synonym_map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<_odata_etag: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, format: string, name: string, synonyms: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($synonym_map_name | is-empty) { error make --unspanned { msg: "path parameter 'synonymMapName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({synonym_map_name: (encode-path-segment $synonym_map_name)} | format pattern "/synonymmaps('{synonym_map_name}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates a new synonym map or updates a synonym map if it already exists.
#
# PUT /synonymmaps('{synonymMapName}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/Update-Synonym-Map
# operationId: SynonymMaps_CreateOrUpdate
# --encryptionKey shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
export def "synonymmaps create-synonym-maps-or-update" [
  synonym_map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --if-match: string # Defines the If-Match condition. The operation will be performed only if the ETag on the server matches this value.
  --if-none-match: string # Defines the If-None-Match condition. The operation will be performed only if the ETag on the server does not match this value.
  --prefer: string@prefer-completer # For HTTP PUT requests, instructs the service to return the created/updated resource on success.
  --odata-etag: string # The ETag of the synonym map.
  --encryption-key: any # A customer-managed encryption key in Azure Key Vault. Keys that you create and manage can be used to encrypt or decrypt data-at-rest in Azure Cognitive Search, such as indexes and synonym maps. — shape: {accessCredentials?: any, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string}
  format: string@format-completer # The format of the synonym map. Only the 'solr' format is currently supported.
  name: string # The name of the synonym map.
  synonyms: string # A series of synonym rules in the specified synonym map format. The rules must be separated by newlines.
]: any -> record<_odata_etag: string, encryptionKey: record<accessCredentials: record<applicationId: string, applicationSecret: string>, keyVaultKeyName: string, keyVaultKeyVersion: string, keyVaultUri: string>, format: string, name: string, synonyms: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($synonym_map_name | is-empty) { error make --unspanned { msg: "path parameter 'synonymMapName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({synonym_map_name: (encode-path-segment $synonym_map_name)} | format pattern "/synonymmaps('{synonym_map_name}')") $qp)
  let req_body = {"@odata.etag": $odata_etag, "encryptionKey": $encryption_key, "format": $format, "name": $name, "synonyms": $synonyms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id, "If-Match": $if_match, "If-None-Match": $if_none_match, "Prefer": $prefer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}
