# Auto-generated client for BigQuery API vv2
# Source: https://api.apis.guru/v2/specs/googleapis.com/bigquery/v2/openapi.json
# Auth: --token flag or $env.BIGQUERY_API_TOKEN

const BASE_URL = "https://bigquery.googleapis.com/bigquery/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BIGQUERY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://bigquery.googleapis.com/bigquery/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def determinism-level-completer [] { ["DETERMINISM_LEVEL_UNSPECIFIED" "DETERMINISTIC" "NOT_DETERMINISTIC"] }
def language-completer [] { ["JAVA" "JAVASCRIPT" "LANGUAGE_UNSPECIFIED" "PYTHON" "SCALA" "SQL"] }
def routine-type-completer [] { ["PROCEDURE" "ROUTINE_TYPE_UNSPECIFIED" "SCALAR_FUNCTION" "TABLE_VALUED_FUNCTION"] }
def view-completer [] { ["BASIC" "FULL" "STORAGE_STATS" "TABLE_METADATA_VIEW_UNSPECIFIED"] }
def projection-completer [] { ["full" "minimal"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "projects list" } } | get name | first)
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

# Lists all projects to which you have been granted any project role.
#
# GET /projects
# operationId: bigquery.projects.list
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of results to return
  --page-token: string # Page token, returned by a previous call, to request the next page of results
]: nothing -> record<etag: string, kind: string, nextPageToken: string, projects: table<friendlyName: string, id: string, kind: string, numericId: string, projectReference: record>, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Lists all datasets in the specified project to which you have been granted the READER dataset role.
#
# GET /projects/{projectId}/datasets
# operationId: bigquery.datasets.list
export def "projects-datasets list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --all: oneof<nothing, bool> # Whether to list all datasets, including hidden ones
  --filter: string # An expression for filtering the results of the request by label. The syntax is "labels.[:]". Multiple filters can be ANDed together by connecting with a space. Example: "labels.department:receiving labels.active". See Filtering datasets using labels for details.
  --max-results: int # The maximum number of results to return
  --page-token: string # Page token, returned by a previous call, to request the next page of results
]: nothing -> record<datasets: table<datasetReference: record, friendlyName: string, id: string, kind: string, labels: record, location: string>, etag: string, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/datasets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "all": $all, "filter": $filter, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Creates a new empty dataset.
#
# POST /projects/{projectId}/datasets
# operationId: bigquery.datasets.insert
# --access item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
# --datasetReference shape: {datasetId?: string, projectId?: string}
# --defaultEncryptionConfiguration shape: {kmsKeyName?: string}
# --tags item shape: {tagKey?: string, tagValue?: string}
export def "projects-datasets create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --access: list # [Optional] An array of objects that define dataset access for one or more entities. You can set this property when inserting or updating a dataset in order to control who is allowed to access the data. If unspecified at dataset creation time, BigQuery adds default dataset access for the following entities: access.specialGroup: projectReaders; access.role: READER; access.specialGroup: projectWriters; access.role: WRITER; access.specialGroup: projectOwners; access.role: OWNER; access.userByEmail: [dataset creator email]; access.role: OWNER; — item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
  --creation-time: string # [Output-only] The time when this dataset was created, in milliseconds since the epoch. (format: int64)
  --dataset-reference: record # shape: {datasetId?: string, projectId?: string}
  --default-collation: string # [Output-only] The default collation of the dataset.
  --default-encryption-configuration: record # shape: {kmsKeyName?: string}
  --default-partition-expiration-ms: string # [Optional] The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. Setting this property overrides the use of defaultTableExpirationMs for partitioned tables: only one of defaultTableExpirationMs and defaultPartitionExpirationMs will be used for any new partitioned table. If you provide an explicit timePartitioning.expirationMs when creating or updating a partitioned table, that value takes precedence over the default partition expiration time indicated by this property. (format: int64)
  --default-rounding-mode: string # [Output-only] The default rounding mode of the dataset.
  --default-table-expiration-ms: string # [Optional] The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. (format: int64)
  --description: string # [Optional] A user-friendly description of the dataset.
  --etag: string # [Output-only] A hash of the resource.
  --friendly-name: string # [Optional] A descriptive name for the dataset.
  --id: string # [Output-only] The fully-qualified unique name of the dataset in the format projectId:datasetId. The dataset name without the project name is given in the datasetId field. When creating a new dataset, leave this field blank, and instead specify the datasetId field.
  --is-case-insensitive: oneof<nothing, bool> # [Optional] Indicates if table names are case insensitive in the dataset.
  --kind: string # [Output-only] The resource type. (default: bigquery#dataset)
  --labels: record # The labels associated with this dataset. You can use these to organize and group your datasets. You can set this property when inserting or updating a dataset. See Creating and Updating Dataset Labels for more information.
  --last-modified-time: string # [Output-only] The date when this dataset or any of its tables was last modified, in milliseconds since the epoch. (format: int64)
  --location: string # The geographic location where the dataset should reside. The default value is US. See details at https://cloud.google.com/bigquery/docs/locations.
  --max-time-travel-hours: string # [Optional] Number of hours for the max time travel for all tables in the dataset. (format: int64)
  --satisfies-pzs: oneof<nothing, bool> # [Output-only] Reserved for future use.
  --self-link: string # [Output-only] A URL that can be used to access the resource again. You can use this URL in Get or Update requests to the resource.
  --storage-billing-model: string # [Optional] Storage billing model to be used for all tables in the dataset. Can be set to PHYSICAL. Default is LOGICAL.
  --tags: list # [Optional]The tags associated with this dataset. Tag keys are globally unique. — item shape: {tagKey?: string, tagValue?: string}
]: any -> record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/datasets") $qp)
  let req_body = {"access": $access, "creationTime": $creation_time, "datasetReference": $dataset_reference, "defaultCollation": $default_collation, "defaultEncryptionConfiguration": $default_encryption_configuration, "defaultPartitionExpirationMs": $default_partition_expiration_ms, "defaultRoundingMode": $default_rounding_mode, "defaultTableExpirationMs": $default_table_expiration_ms, "description": $description, "etag": $etag, "friendlyName": $friendly_name, "id": $id, "isCaseInsensitive": $is_case_insensitive, "kind": $kind, "labels": $labels, "lastModifiedTime": $last_modified_time, "location": $location, "maxTimeTravelHours": $max_time_travel_hours, "satisfiesPzs": $satisfies_pzs, "selfLink": $self_link, "storageBillingModel": $storage_billing_model, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Deletes the dataset specified by the datasetId value. Before you can delete a dataset, you must delete all its tables, either manually or by specifying deleteContents. Immediately after deletion, you can create another dataset with the same name.
#
# DELETE /projects/{projectId}/datasets/{datasetId}
# operationId: bigquery.datasets.delete
export def "projects-datasets delete" [
  project_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --delete-contents: oneof<nothing, bool> # If True, delete all the tables in the dataset. If False and the dataset contains tables, the request will fail. Default is False
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "deleteContents" $delete_contents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "deleteContents": $delete_contents} | compact), body: null}
}

# Returns the dataset specified by datasetID.
#
# GET /projects/{projectId}/datasets/{datasetId}
# operationId: bigquery.datasets.get
export def "projects-datasets get" [
  project_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Updates information in an existing dataset. The update method replaces the entire dataset resource, whereas the patch method only replaces fields that are provided in the submitted dataset resource. This method supports patch semantics.
#
# PATCH /projects/{projectId}/datasets/{datasetId}
# operationId: bigquery.datasets.patch
# --access item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
# --datasetReference shape: {datasetId?: string, projectId?: string}
# --defaultEncryptionConfiguration shape: {kmsKeyName?: string}
# --tags item shape: {tagKey?: string, tagValue?: string}
export def "projects-datasets update-by-project-id-dataset-id" [
  project_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --access: list # [Optional] An array of objects that define dataset access for one or more entities. You can set this property when inserting or updating a dataset in order to control who is allowed to access the data. If unspecified at dataset creation time, BigQuery adds default dataset access for the following entities: access.specialGroup: projectReaders; access.role: READER; access.specialGroup: projectWriters; access.role: WRITER; access.specialGroup: projectOwners; access.role: OWNER; access.userByEmail: [dataset creator email]; access.role: OWNER; — item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
  --creation-time: string # [Output-only] The time when this dataset was created, in milliseconds since the epoch. (format: int64)
  --dataset-reference: record # shape: {datasetId?: string, projectId?: string}
  --default-collation: string # [Output-only] The default collation of the dataset.
  --default-encryption-configuration: record # shape: {kmsKeyName?: string}
  --default-partition-expiration-ms: string # [Optional] The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. Setting this property overrides the use of defaultTableExpirationMs for partitioned tables: only one of defaultTableExpirationMs and defaultPartitionExpirationMs will be used for any new partitioned table. If you provide an explicit timePartitioning.expirationMs when creating or updating a partitioned table, that value takes precedence over the default partition expiration time indicated by this property. (format: int64)
  --default-rounding-mode: string # [Output-only] The default rounding mode of the dataset.
  --default-table-expiration-ms: string # [Optional] The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. (format: int64)
  --description: string # [Optional] A user-friendly description of the dataset.
  --etag: string # [Output-only] A hash of the resource.
  --friendly-name: string # [Optional] A descriptive name for the dataset.
  --id: string # [Output-only] The fully-qualified unique name of the dataset in the format projectId:datasetId. The dataset name without the project name is given in the datasetId field. When creating a new dataset, leave this field blank, and instead specify the datasetId field.
  --is-case-insensitive: oneof<nothing, bool> # [Optional] Indicates if table names are case insensitive in the dataset.
  --kind: string # [Output-only] The resource type. (default: bigquery#dataset)
  --labels: record # The labels associated with this dataset. You can use these to organize and group your datasets. You can set this property when inserting or updating a dataset. See Creating and Updating Dataset Labels for more information.
  --last-modified-time: string # [Output-only] The date when this dataset or any of its tables was last modified, in milliseconds since the epoch. (format: int64)
  --location: string # The geographic location where the dataset should reside. The default value is US. See details at https://cloud.google.com/bigquery/docs/locations.
  --max-time-travel-hours: string # [Optional] Number of hours for the max time travel for all tables in the dataset. (format: int64)
  --satisfies-pzs: oneof<nothing, bool> # [Output-only] Reserved for future use.
  --self-link: string # [Output-only] A URL that can be used to access the resource again. You can use this URL in Get or Update requests to the resource.
  --storage-billing-model: string # [Optional] Storage billing model to be used for all tables in the dataset. Can be set to PHYSICAL. Default is LOGICAL.
  --tags: list # [Optional]The tags associated with this dataset. Tag keys are globally unique. — item shape: {tagKey?: string, tagValue?: string}
]: any -> record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}") $qp)
  let req_body = {"access": $access, "creationTime": $creation_time, "datasetReference": $dataset_reference, "defaultCollation": $default_collation, "defaultEncryptionConfiguration": $default_encryption_configuration, "defaultPartitionExpirationMs": $default_partition_expiration_ms, "defaultRoundingMode": $default_rounding_mode, "defaultTableExpirationMs": $default_table_expiration_ms, "description": $description, "etag": $etag, "friendlyName": $friendly_name, "id": $id, "isCaseInsensitive": $is_case_insensitive, "kind": $kind, "labels": $labels, "lastModifiedTime": $last_modified_time, "location": $location, "maxTimeTravelHours": $max_time_travel_hours, "satisfiesPzs": $satisfies_pzs, "selfLink": $self_link, "storageBillingModel": $storage_billing_model, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Updates information in an existing dataset. The update method replaces the entire dataset resource, whereas the patch method only replaces fields that are provided in the submitted dataset resource.
#
# PUT /projects/{projectId}/datasets/{datasetId}
# operationId: bigquery.datasets.update
# --access item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
# --datasetReference shape: {datasetId?: string, projectId?: string}
# --defaultEncryptionConfiguration shape: {kmsKeyName?: string}
# --tags item shape: {tagKey?: string, tagValue?: string}
export def "projects-datasets update-by-project-id-dataset-id-1" [
  project_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --access: list # [Optional] An array of objects that define dataset access for one or more entities. You can set this property when inserting or updating a dataset in order to control who is allowed to access the data. If unspecified at dataset creation time, BigQuery adds default dataset access for the following entities: access.specialGroup: projectReaders; access.role: READER; access.specialGroup: projectWriters; access.role: WRITER; access.specialGroup: projectOwners; access.role: OWNER; access.userByEmail: [dataset creator email]; access.role: OWNER; — item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
  --creation-time: string # [Output-only] The time when this dataset was created, in milliseconds since the epoch. (format: int64)
  --dataset-reference: record # shape: {datasetId?: string, projectId?: string}
  --default-collation: string # [Output-only] The default collation of the dataset.
  --default-encryption-configuration: record # shape: {kmsKeyName?: string}
  --default-partition-expiration-ms: string # [Optional] The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. Setting this property overrides the use of defaultTableExpirationMs for partitioned tables: only one of defaultTableExpirationMs and defaultPartitionExpirationMs will be used for any new partitioned table. If you provide an explicit timePartitioning.expirationMs when creating or updating a partitioned table, that value takes precedence over the default partition expiration time indicated by this property. (format: int64)
  --default-rounding-mode: string # [Output-only] The default rounding mode of the dataset.
  --default-table-expiration-ms: string # [Optional] The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. (format: int64)
  --description: string # [Optional] A user-friendly description of the dataset.
  --etag: string # [Output-only] A hash of the resource.
  --friendly-name: string # [Optional] A descriptive name for the dataset.
  --id: string # [Output-only] The fully-qualified unique name of the dataset in the format projectId:datasetId. The dataset name without the project name is given in the datasetId field. When creating a new dataset, leave this field blank, and instead specify the datasetId field.
  --is-case-insensitive: oneof<nothing, bool> # [Optional] Indicates if table names are case insensitive in the dataset.
  --kind: string # [Output-only] The resource type. (default: bigquery#dataset)
  --labels: record # The labels associated with this dataset. You can use these to organize and group your datasets. You can set this property when inserting or updating a dataset. See Creating and Updating Dataset Labels for more information.
  --last-modified-time: string # [Output-only] The date when this dataset or any of its tables was last modified, in milliseconds since the epoch. (format: int64)
  --location: string # The geographic location where the dataset should reside. The default value is US. See details at https://cloud.google.com/bigquery/docs/locations.
  --max-time-travel-hours: string # [Optional] Number of hours for the max time travel for all tables in the dataset. (format: int64)
  --satisfies-pzs: oneof<nothing, bool> # [Output-only] Reserved for future use.
  --self-link: string # [Output-only] A URL that can be used to access the resource again. You can use this URL in Get or Update requests to the resource.
  --storage-billing-model: string # [Optional] Storage billing model to be used for all tables in the dataset. Can be set to PHYSICAL. Default is LOGICAL.
  --tags: list # [Optional]The tags associated with this dataset. Tag keys are globally unique. — item shape: {tagKey?: string, tagValue?: string}
]: any -> record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}") $qp)
  let req_body = {"access": $access, "creationTime": $creation_time, "datasetReference": $dataset_reference, "defaultCollation": $default_collation, "defaultEncryptionConfiguration": $default_encryption_configuration, "defaultPartitionExpirationMs": $default_partition_expiration_ms, "defaultRoundingMode": $default_rounding_mode, "defaultTableExpirationMs": $default_table_expiration_ms, "description": $description, "etag": $etag, "friendlyName": $friendly_name, "id": $id, "isCaseInsensitive": $is_case_insensitive, "kind": $kind, "labels": $labels, "lastModifiedTime": $last_modified_time, "location": $location, "maxTimeTravelHours": $max_time_travel_hours, "satisfiesPzs": $satisfies_pzs, "selfLink": $self_link, "storageBillingModel": $storage_billing_model, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Lists all models in the specified dataset. Requires the READER dataset role. After retrieving the list of models, you can get information about a particular model by calling the models.get method.
#
# GET /projects/{projectId}/datasets/{datasetId}/models
# operationId: bigquery.models.list
export def "projects-datasets-models list" [
  project_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of results to return in a single response page. Leverage the page tokens to iterate through the entire collection.
  --page-token: string # Page token, returned by a previous call to request the next page of results
]: nothing -> record<models: table<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record, etag: string, expirationTime: string, featureColumns: list, friendlyName: string, hparamSearchSpaces: record, hparamTrials: list, labelColumns: list, labels: record, lastModifiedTime: string, location: string, modelReference: record, modelType: string, optimalTrialIds: list, trainingRuns: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Deletes the model specified by modelId from the dataset.
#
# DELETE /projects/{projectId}/datasets/{datasetId}/models/{modelId}
# operationId: bigquery.models.delete
export def "projects-datasets-models delete" [
  project_id: string
  dataset_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), model_id: (encode-path-segment $model_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/models/{model_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Gets the specified model resource by model ID.
#
# GET /projects/{projectId}/datasets/{datasetId}/models/{modelId}
# operationId: bigquery.models.get
export def "projects-datasets-models get" [
  project_id: string
  dataset_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, featureColumns: table<name: string, type: record>, friendlyName: string, hparamSearchSpaces: record<activationFn: record<candidates: list>, batchSize: record<candidates: record, range: record>, boosterType: record<candidates: list>, colsampleBylevel: record<candidates: record, range: record>, colsampleBynode: record<candidates: record, range: record>, colsampleBytree: record<candidates: record, range: record>, dartNormalizeType: record<candidates: list>, dropout: record<candidates: record, range: record>, hiddenUnits: record<candidates: list>, l1Reg: record<candidates: record, range: record>, l2Reg: record<candidates: record, range: record>, learnRate: record<candidates: record, range: record>, maxTreeDepth: record<candidates: record, range: record>, minSplitLoss: record<candidates: record, range: record>, minTreeChildWeight: record<candidates: record, range: record>, numClusters: record<candidates: record, range: record>, numFactors: record<candidates: record, range: record>, numParallelTree: record<candidates: record, range: record>, optimizer: record<candidates: list>, subsample: record<candidates: record, range: record>, treeMethod: record<candidates: list>, walsAlpha: record<candidates: record, range: record>>, hparamTrials: table<endTimeMs: string, errorMessage: string, evalLoss: float, evaluationMetrics: record, hparamTuningEvaluationMetrics: record, hparams: record, startTimeMs: string, status: string, trainingLoss: float, trialId: string>, labelColumns: table<name: string, type: record>, labels: record, lastModifiedTime: string, location: string, modelReference: record<datasetId: string, modelId: string, projectId: string>, modelType: string, optimalTrialIds: list<string>, trainingRuns: table<classLevelGlobalExplanations: list, dataSplitResult: record, evaluationMetrics: record, modelLevelGlobalExplanation: record, results: list, startTime: string, trainingOptions: record, trainingStartTime: string, vertexAiModelId: string, vertexAiModelVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), model_id: (encode-path-segment $model_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/models/{model_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Patch specific fields in the specified model.
#
# PATCH /projects/{projectId}/datasets/{datasetId}/models/{modelId}
# operationId: bigquery.models.patch
# --encryptionConfiguration shape: {kmsKeyName?: string}
# --featureColumns item shape: {name?: string, type?: record}
# --hparamSearchSpaces shape: {activationFn?: record, batchSize?: record, boosterType?: record, colsampleBylevel?: record, colsampleBynode?: record, colsampleBytree?: record, dartNormalizeType?: record, dropout?: record, hiddenUnits?: record, l1Reg?: record, l2Reg?: record, learnRate?: record, maxTreeDepth?: record, minSplitLoss?: record, minTreeChildWeight?: record, numClusters?: record, numFactors?: record, numParallelTree?: record, optimizer?: record, subsample?: record, treeMethod?: record, walsAlpha?: record}
# --hparamTrials item shape: {endTimeMs?: string, errorMessage?: string, evalLoss?: float, evaluationMetrics?: record, hparamTuningEvaluationMetrics?: record, hparams?: record, startTimeMs?: string, status?: "TRIAL_STATUS_UNSPECIFIED"|"NOT_STARTED"|"RUNNING"|"SUCCEEDED"|"FAILED"|"INFEASIBLE"|"STOPPED_EARLY", trainingLoss?: float, trialId?: string}
# --labelColumns item shape: {name?: string, type?: record}
# --modelReference shape: {datasetId?: string, modelId?: string, projectId?: string}
# --trainingRuns item shape: {dataSplitResult?: record, evaluationMetrics?: record, modelLevelGlobalExplanation?: record, trainingOptions?: record, vertexAiModelId?: string}
export def "projects-datasets-models update" [
  project_id: string
  dataset_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --best-trial-id: string # The best trial_id across all training runs. (format: int64)
  --description: string # Optional. A user-friendly description of this model.
  --encryption-configuration: record # shape: {kmsKeyName?: string}
  --expiration-time: string # Optional. The time when this model expires, in milliseconds since the epoch. If not present, the model will persist indefinitely. Expired models will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created models. (format: int64)
  --friendly-name: string # Optional. A descriptive name for this model.
  --hparam-search-spaces: record # Hyperparameter search spaces. These should be a subset of training_options. — shape: {activationFn?: record, batchSize?: record, boosterType?: record, colsampleBylevel?: record, colsampleBynode?: record, colsampleBytree?: record, dartNormalizeType?: record, dropout?: record, hiddenUnits?: record, l1Reg?: record, l2Reg?: record, learnRate?: record, maxTreeDepth?: record, minSplitLoss?: record, minTreeChildWeight?: record, numClusters?: record, numFactors?: record, numParallelTree?: record, optimizer?: record, subsample?: record, treeMethod?: record, walsAlpha?: record}
  --labels: record # The labels associated with this model. You can use these to organize and group your models. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --model-reference: record # shape: {datasetId?: string, modelId?: string, projectId?: string}
  --training-runs: list # Information for all training runs in increasing order of start_time. — item shape: {dataSplitResult?: record, evaluationMetrics?: record, modelLevelGlobalExplanation?: record, trainingOptions?: record, vertexAiModelId?: string}
]: any -> record<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, featureColumns: table<name: string, type: record>, friendlyName: string, hparamSearchSpaces: record<activationFn: record<candidates: list>, batchSize: record<candidates: record, range: record>, boosterType: record<candidates: list>, colsampleBylevel: record<candidates: record, range: record>, colsampleBynode: record<candidates: record, range: record>, colsampleBytree: record<candidates: record, range: record>, dartNormalizeType: record<candidates: list>, dropout: record<candidates: record, range: record>, hiddenUnits: record<candidates: list>, l1Reg: record<candidates: record, range: record>, l2Reg: record<candidates: record, range: record>, learnRate: record<candidates: record, range: record>, maxTreeDepth: record<candidates: record, range: record>, minSplitLoss: record<candidates: record, range: record>, minTreeChildWeight: record<candidates: record, range: record>, numClusters: record<candidates: record, range: record>, numFactors: record<candidates: record, range: record>, numParallelTree: record<candidates: record, range: record>, optimizer: record<candidates: list>, subsample: record<candidates: record, range: record>, treeMethod: record<candidates: list>, walsAlpha: record<candidates: record, range: record>>, hparamTrials: table<endTimeMs: string, errorMessage: string, evalLoss: float, evaluationMetrics: record, hparamTuningEvaluationMetrics: record, hparams: record, startTimeMs: string, status: string, trainingLoss: float, trialId: string>, labelColumns: table<name: string, type: record>, labels: record, lastModifiedTime: string, location: string, modelReference: record<datasetId: string, modelId: string, projectId: string>, modelType: string, optimalTrialIds: list<string>, trainingRuns: table<classLevelGlobalExplanations: list, dataSplitResult: record, evaluationMetrics: record, modelLevelGlobalExplanation: record, results: list, startTime: string, trainingOptions: record, trainingStartTime: string, vertexAiModelId: string, vertexAiModelVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), model_id: (encode-path-segment $model_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/models/{model_id}") $qp)
  let req_body = {"bestTrialId": $best_trial_id, "description": $description, "encryptionConfiguration": $encryption_configuration, "expirationTime": $expiration_time, "friendlyName": $friendly_name, "hparamSearchSpaces": $hparam_search_spaces, "labels": $labels, "modelReference": $model_reference, "trainingRuns": $training_runs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Lists all routines in the specified dataset. Requires the READER dataset role.
#
# GET /projects/{projectId}/datasets/{datasetId}/routines
# operationId: bigquery.routines.list
export def "projects-datasets-routines list" [
  project_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --filter: string # If set, then only the Routines matching this filter are returned. The current supported form is either "routine_type:" or "routineType:", where is a RoutineType enum. Example: "routineType:SCALAR_FUNCTION".
  --max-results: int # The maximum number of results to return in a single response page. Leverage the page tokens to iterate through the entire collection.
  --page-token: string # Page token, returned by a previous call, to request the next page of results
  --read-mask: string # If set, then only the Routine fields in the field mask, as well as project_id, dataset_id and routine_id, are returned in the response. If unset, then the following Routine fields are returned: etag, project_id, dataset_id, routine_id, routine_type, creation_time, last_modified_time, and language.
]: nothing -> record<nextPageToken: string, routines: table<arguments: list, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list, language: string, lastModifiedTime: string, remoteFunctionOptions: record, returnTableType: record, returnType: record, routineReference: record, routineType: string, sparkOptions: record, strictMode: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "readMask" $read_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/routines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "filter": $filter, "maxResults": $max_results, "pageToken": $page_token, "readMask": $read_mask} | compact), body: null}
}

# Creates a new routine in the dataset.
#
# POST /projects/{projectId}/datasets/{datasetId}/routines
# operationId: bigquery.routines.insert
# --arguments item shape: {argumentKind?: "ARGUMENT_KIND_UNSPECIFIED"|"FIXED_TYPE"|"ANY_TYPE", dataType?: record, mode?: "MODE_UNSPECIFIED"|"IN"|"OUT"|"INOUT", name?: string}
# --remoteFunctionOptions shape: {connection?: string, endpoint?: string, maxBatchingRows?: string, userDefinedContext?: record}
# --returnTableType shape: {columns?: list}
# --returnType shape: {arrayElementType?: record, structType?: record, typeKind?: "TYPE_KIND_UNSPECIFIED"|"INT64"|"BOOL"|"FLOAT64"|"STRING"|"BYTES"|"TIMESTAMP"|"DATE"|"TIME"|"DATETIME"|"INTERVAL"|"GEOGRAPHY"|"NUMERIC"|"BIGNUMERIC"|"JSON"|"ARRAY"|"STRUCT"}
# --routineReference shape: {datasetId?: string, projectId?: string, routineId?: string}
# --sparkOptions shape: {archiveUris?: list<string>, connection?: string, containerImage?: string, fileUris?: list<string>, jarUris?: list<string>, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list<string>, runtimeVersion?: string}
export def "projects-datasets-routines create" [
  project_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --arguments: list # Optional. — item shape: {argumentKind?: "ARGUMENT_KIND_UNSPECIFIED"|"FIXED_TYPE"|"ANY_TYPE", dataType?: record, mode?: "MODE_UNSPECIFIED"|"IN"|"OUT"|"INOUT", name?: string}
  --definition-body: string # Required. The body of the routine. For functions, this is the expression in the AS clause. If language=SQL, it is the substring inside (but excluding) the parentheses. For example, for the function created with the following statement: `CREATE FUNCTION JoinLines(x string, y string) as (concat(x, "\n", y))` The definition_body is `concat(x, "\n", y)` (\n is not replaced with linebreak). If language=JAVASCRIPT, it is the evaluated string in the AS clause. For example, for the function created with the following statement: `CREATE FUNCTION f() RETURNS STRING LANGUAGE js AS 'return "\n";\n'` The definition_body is `return "\n";\n` Note that both \n are replaced with linebreaks.
  --description: string # Optional. The description of the routine, if defined.
  --determinism-level: string@determinism-level-completer # Optional. The determinism level of the JavaScript UDF, if defined.
  --imported-libraries: list<string> # Optional. If language = "JAVASCRIPT", this field stores the path of the imported JAVASCRIPT libraries.
  --language: string@language-completer # Optional. Defaults to "SQL" if remote_function_options field is absent, not set otherwise.
  --remote-function-options: record # Options for a remote user-defined function. — shape: {connection?: string, endpoint?: string, maxBatchingRows?: string, userDefinedContext?: record}
  --return-table-type: record # A table type — shape: {columns?: list}
  --return-type: record # The data type of a variable such as a function argument. Examples include: * INT64: `{"typeKind": "INT64"}` * ARRAY: { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "STRING"} } * STRUCT>: { "typeKind": "STRUCT", "structType": { "fields": [ { "name": "x", "type": {"typeKind": "STRING"} }, { "name": "y", "type": { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "DATE"} } } ] } } — shape: {arrayElementType?: record, structType?: record, typeKind?: "TYPE_KIND_UNSPECIFIED"|"INT64"|"BOOL"|"FLOAT64"|"STRING"|"BYTES"|"TIMESTAMP"|"DATE"|"TIME"|"DATETIME"|"INTERVAL"|"GEOGRAPHY"|"NUMERIC"|"BIGNUMERIC"|"JSON"|"ARRAY"|"STRUCT"}
  --routine-reference: record # shape: {datasetId?: string, projectId?: string, routineId?: string}
  --routine-type: string@routine-type-completer # Required. The type of routine.
  --spark-options: record # Options for a user-defined Spark routine. — shape: {archiveUris?: list<string>, connection?: string, containerImage?: string, fileUris?: list<string>, jarUris?: list<string>, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list<string>, runtimeVersion?: string}
  --strict-mode: oneof<nothing, bool> # Optional. Can be set for procedures only. If true (default), the definition body will be validated in the creation and the updates of the procedure. For procedures with an argument of ANY TYPE, the definition body validtion is not supported at creation/update time, and thus this field must be set to false explicitly.
]: any -> record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/routines") $qp)
  let req_body = {"arguments": $arguments, "definitionBody": $definition_body, "description": $description, "determinismLevel": $determinism_level, "importedLibraries": $imported_libraries, "language": $language, "remoteFunctionOptions": $remote_function_options, "returnTableType": $return_table_type, "returnType": $return_type, "routineReference": $routine_reference, "routineType": $routine_type, "sparkOptions": $spark_options, "strictMode": $strict_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Deletes the routine specified by routineId from the dataset.
#
# DELETE /projects/{projectId}/datasets/{datasetId}/routines/{routineId}
# operationId: bigquery.routines.delete
export def "projects-datasets-routines delete" [
  project_id: string
  dataset_id: string
  routine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($routine_id | is-empty) { error make --unspanned { msg: "path parameter 'routineId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), routine_id: (encode-path-segment $routine_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/routines/{routine_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Gets the specified routine resource by routine ID.
#
# GET /projects/{projectId}/datasets/{datasetId}/routines/{routineId}
# operationId: bigquery.routines.get
export def "projects-datasets-routines get" [
  project_id: string
  dataset_id: string
  routine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --read-mask: string # If set, only the Routine fields in the field mask are returned in the response. If unset, all Routine fields are returned.
]: nothing -> record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($routine_id | is-empty) { error make --unspanned { msg: "path parameter 'routineId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "readMask" $read_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), routine_id: (encode-path-segment $routine_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/routines/{routine_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "readMask": $read_mask} | compact), body: null}
}

# Updates information in an existing routine. The update method replaces the entire Routine resource.
#
# PUT /projects/{projectId}/datasets/{datasetId}/routines/{routineId}
# operationId: bigquery.routines.update
# --arguments item shape: {argumentKind?: "ARGUMENT_KIND_UNSPECIFIED"|"FIXED_TYPE"|"ANY_TYPE", dataType?: record, mode?: "MODE_UNSPECIFIED"|"IN"|"OUT"|"INOUT", name?: string}
# --remoteFunctionOptions shape: {connection?: string, endpoint?: string, maxBatchingRows?: string, userDefinedContext?: record}
# --returnTableType shape: {columns?: list}
# --returnType shape: {arrayElementType?: record, structType?: record, typeKind?: "TYPE_KIND_UNSPECIFIED"|"INT64"|"BOOL"|"FLOAT64"|"STRING"|"BYTES"|"TIMESTAMP"|"DATE"|"TIME"|"DATETIME"|"INTERVAL"|"GEOGRAPHY"|"NUMERIC"|"BIGNUMERIC"|"JSON"|"ARRAY"|"STRUCT"}
# --routineReference shape: {datasetId?: string, projectId?: string, routineId?: string}
# --sparkOptions shape: {archiveUris?: list<string>, connection?: string, containerImage?: string, fileUris?: list<string>, jarUris?: list<string>, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list<string>, runtimeVersion?: string}
export def "projects-datasets-routines update" [
  project_id: string
  dataset_id: string
  routine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --arguments: list # Optional. — item shape: {argumentKind?: "ARGUMENT_KIND_UNSPECIFIED"|"FIXED_TYPE"|"ANY_TYPE", dataType?: record, mode?: "MODE_UNSPECIFIED"|"IN"|"OUT"|"INOUT", name?: string}
  --definition-body: string # Required. The body of the routine. For functions, this is the expression in the AS clause. If language=SQL, it is the substring inside (but excluding) the parentheses. For example, for the function created with the following statement: `CREATE FUNCTION JoinLines(x string, y string) as (concat(x, "\n", y))` The definition_body is `concat(x, "\n", y)` (\n is not replaced with linebreak). If language=JAVASCRIPT, it is the evaluated string in the AS clause. For example, for the function created with the following statement: `CREATE FUNCTION f() RETURNS STRING LANGUAGE js AS 'return "\n";\n'` The definition_body is `return "\n";\n` Note that both \n are replaced with linebreaks.
  --description: string # Optional. The description of the routine, if defined.
  --determinism-level: string@determinism-level-completer # Optional. The determinism level of the JavaScript UDF, if defined.
  --imported-libraries: list<string> # Optional. If language = "JAVASCRIPT", this field stores the path of the imported JAVASCRIPT libraries.
  --language: string@language-completer # Optional. Defaults to "SQL" if remote_function_options field is absent, not set otherwise.
  --remote-function-options: record # Options for a remote user-defined function. — shape: {connection?: string, endpoint?: string, maxBatchingRows?: string, userDefinedContext?: record}
  --return-table-type: record # A table type — shape: {columns?: list}
  --return-type: record # The data type of a variable such as a function argument. Examples include: * INT64: `{"typeKind": "INT64"}` * ARRAY: { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "STRING"} } * STRUCT>: { "typeKind": "STRUCT", "structType": { "fields": [ { "name": "x", "type": {"typeKind": "STRING"} }, { "name": "y", "type": { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "DATE"} } } ] } } — shape: {arrayElementType?: record, structType?: record, typeKind?: "TYPE_KIND_UNSPECIFIED"|"INT64"|"BOOL"|"FLOAT64"|"STRING"|"BYTES"|"TIMESTAMP"|"DATE"|"TIME"|"DATETIME"|"INTERVAL"|"GEOGRAPHY"|"NUMERIC"|"BIGNUMERIC"|"JSON"|"ARRAY"|"STRUCT"}
  --routine-reference: record # shape: {datasetId?: string, projectId?: string, routineId?: string}
  --routine-type: string@routine-type-completer # Required. The type of routine.
  --spark-options: record # Options for a user-defined Spark routine. — shape: {archiveUris?: list<string>, connection?: string, containerImage?: string, fileUris?: list<string>, jarUris?: list<string>, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list<string>, runtimeVersion?: string}
  --strict-mode: oneof<nothing, bool> # Optional. Can be set for procedures only. If true (default), the definition body will be validated in the creation and the updates of the procedure. For procedures with an argument of ANY TYPE, the definition body validtion is not supported at creation/update time, and thus this field must be set to false explicitly.
]: any -> record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($routine_id | is-empty) { error make --unspanned { msg: "path parameter 'routineId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), routine_id: (encode-path-segment $routine_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/routines/{routine_id}") $qp)
  let req_body = {"arguments": $arguments, "definitionBody": $definition_body, "description": $description, "determinismLevel": $determinism_level, "importedLibraries": $imported_libraries, "language": $language, "remoteFunctionOptions": $remote_function_options, "returnTableType": $return_table_type, "returnType": $return_type, "routineReference": $routine_reference, "routineType": $routine_type, "sparkOptions": $spark_options, "strictMode": $strict_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Lists all tables in the specified dataset. Requires the READER dataset role.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables
# operationId: bigquery.tables.list
export def "projects-datasets-tables list" [
  project_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of results to return
  --page-token: string # Page token, returned by a previous call, to request the next page of results
]: nothing -> record<etag: string, kind: string, nextPageToken: string, tables: table<clustering: record, creationTime: string, expirationTime: string, friendlyName: string, id: string, kind: string, labels: record, rangePartitioning: record, tableReference: record, timePartitioning: record, type: string, view: record>, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/tables") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Creates a new, empty table in the dataset.
#
# POST /projects/{projectId}/datasets/{datasetId}/tables
# operationId: bigquery.tables.insert
# --cloneDefinition shape: {baseTableReference?: record, cloneTime?: string}
# --clustering shape: {fields?: list<string>}
# --encryptionConfiguration shape: {kmsKeyName?: string}
# --externalDataConfiguration shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list<string>, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list<string>}
# --materializedView shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
# --model shape: {modelOptions?: record, trainingRuns?: list}
# --rangePartitioning shape: {field?: string, range?: record}
# --schema shape: {fields?: list}
# --snapshotDefinition shape: {baseTableReference?: record, snapshotTime?: string}
# --streamingBuffer shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
# --tableReference shape: {datasetId?: string, projectId?: string, tableId?: string}
# --timePartitioning shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
# --view shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
export def "projects-datasets-tables create" [
  project_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --clone-definition: record # shape: {baseTableReference?: record, cloneTime?: string}
  --clustering: record # shape: {fields?: list<string>}
  --creation-time: string # [Output-only] The time when this table was created, in milliseconds since the epoch. (format: int64)
  --default-collation: string # [Output-only] The default collation of the table.
  --default-rounding-mode: string # [Output-only] The default rounding mode of the table.
  --description: string # [Optional] A user-friendly description of this table.
  --encryption-configuration: record # shape: {kmsKeyName?: string}
  --etag: string # [Output-only] A hash of the table metadata. Used to ensure there were no concurrent modifications to the resource when attempting an update. Not guaranteed to change when the table contents or the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  --expiration-time: string # [Optional] The time when this table expires, in milliseconds since the epoch. If not present, the table will persist indefinitely. Expired tables will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created tables. (format: int64)
  --external-data-configuration: record # shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list<string>, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list<string>}
  --friendly-name: string # [Optional] A descriptive name for this table.
  --id: string # [Output-only] An opaque ID uniquely identifying the table.
  --kind: string # [Output-only] The type of the resource. (default: bigquery#table)
  --labels: record # The labels associated with this table. You can use these to organize and group your tables. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --last-modified-time: string # [Output-only] The time when this table was last modified, in milliseconds since the epoch. (format: uint64)
  --location: string # [Output-only] The geographic location where the table resides. This value is inherited from the dataset.
  --materialized-view: record # shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
  --max-staleness: string # [Optional] Max staleness of data that could be returned when table or materialized view is queried (formatted as Google SQL Interval type). (format: byte)
  --model: record # shape: {modelOptions?: record, trainingRuns?: list}
  --num-bytes: string # [Output-only] The size of this table in bytes, excluding any data in the streaming buffer. (format: int64)
  --num-long-term-bytes: string # [Output-only] The number of bytes in the table that are considered "long-term storage". (format: int64)
  --num-physical-bytes: string # [Output-only] [TrustedTester] The physical size of this table in bytes, excluding any data in the streaming buffer. This includes compression and storage used for time travel. (format: int64)
  --num-rows: string # [Output-only] The number of rows of data in this table, excluding any data in the streaming buffer. (format: uint64)
  --num-active-logical-bytes: string # [Output-only] Number of logical bytes that are less than 90 days old. (format: int64)
  --num-active-physical-bytes: string # [Output-only] Number of physical bytes less than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-long-term-logical-bytes: string # [Output-only] Number of logical bytes that are more than 90 days old. (format: int64)
  --num-long-term-physical-bytes: string # [Output-only] Number of physical bytes more than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-partitions: string # [Output-only] The number of partitions present in the table or materialized view. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-time-travel-physical-bytes: string # [Output-only] Number of physical bytes used by time travel storage (deleted or changed data). This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-total-logical-bytes: string # [Output-only] Total number of logical bytes in the table or materialized view. (format: int64)
  --num-total-physical-bytes: string # [Output-only] The physical size of this table in bytes. This also includes storage used for time travel. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --range-partitioning: record # shape: {field?: string, range?: record}
  --require-partition-filter: oneof<nothing, bool> # [Optional] If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. (default: false)
  --schema: record # shape: {fields?: list}
  --self-link: string # [Output-only] A URL that can be used to access this resource again.
  --snapshot-definition: record # shape: {baseTableReference?: record, snapshotTime?: string}
  --streaming-buffer: record # shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
  --table-reference: record # shape: {datasetId?: string, projectId?: string, tableId?: string}
  --time-partitioning: record # shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
  --type: string # [Output-only] Describes the table type. The following values are supported: TABLE: A normal BigQuery table. VIEW: A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only table that is a copy of another table. [TrustedTester] MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table that references data stored in an external storage system, such as Google Cloud Storage. The default value is TABLE.
  --view: record # shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
]: any -> record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/tables") $qp)
  let req_body = {"cloneDefinition": $clone_definition, "clustering": $clustering, "creationTime": $creation_time, "defaultCollation": $default_collation, "defaultRoundingMode": $default_rounding_mode, "description": $description, "encryptionConfiguration": $encryption_configuration, "etag": $etag, "expirationTime": $expiration_time, "externalDataConfiguration": $external_data_configuration, "friendlyName": $friendly_name, "id": $id, "kind": $kind, "labels": $labels, "lastModifiedTime": $last_modified_time, "location": $location, "materializedView": $materialized_view, "maxStaleness": $max_staleness, "model": $model, "numBytes": $num_bytes, "numLongTermBytes": $num_long_term_bytes, "numPhysicalBytes": $num_physical_bytes, "numRows": $num_rows, "num_active_logical_bytes": $num_active_logical_bytes, "num_active_physical_bytes": $num_active_physical_bytes, "num_long_term_logical_bytes": $num_long_term_logical_bytes, "num_long_term_physical_bytes": $num_long_term_physical_bytes, "num_partitions": $num_partitions, "num_time_travel_physical_bytes": $num_time_travel_physical_bytes, "num_total_logical_bytes": $num_total_logical_bytes, "num_total_physical_bytes": $num_total_physical_bytes, "rangePartitioning": $range_partitioning, "requirePartitionFilter": $require_partition_filter, "schema": $schema, "selfLink": $self_link, "snapshotDefinition": $snapshot_definition, "streamingBuffer": $streaming_buffer, "tableReference": $table_reference, "timePartitioning": $time_partitioning, "type": $type, "view": $view} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Deletes the table specified by tableId from the dataset. If the table contains data, all the data will be deleted.
#
# DELETE /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# operationId: bigquery.tables.delete
export def "projects-datasets-tables delete" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), table_id: (encode-path-segment $table_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/tables/{table_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Gets the specified table resource by table ID. This method does not return the data in the table, it only returns the table resource, which describes the structure of this table.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# operationId: bigquery.tables.get
export def "projects-datasets-tables get" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --selected-fields: string # List of fields to return (comma-separated). If unspecified, all fields are returned
  --view: string@view-completer # Specifies the view that determines which table information is returned. By default, basic table information and storage statistics (STORAGE_STATS) are returned.
]: nothing -> record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "selectedFields" $selected_fields "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), table_id: (encode-path-segment $table_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/tables/{table_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "selectedFields": $selected_fields, "view": $view} | compact), body: null}
}

# Updates information in an existing table. The update method replaces the entire table resource, whereas the patch method only replaces fields that are provided in the submitted table resource. This method supports patch semantics.
#
# PATCH /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# operationId: bigquery.tables.patch
# --cloneDefinition shape: {baseTableReference?: record, cloneTime?: string}
# --clustering shape: {fields?: list<string>}
# --encryptionConfiguration shape: {kmsKeyName?: string}
# --externalDataConfiguration shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list<string>, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list<string>}
# --materializedView shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
# --model shape: {modelOptions?: record, trainingRuns?: list}
# --rangePartitioning shape: {field?: string, range?: record}
# --schema shape: {fields?: list}
# --snapshotDefinition shape: {baseTableReference?: record, snapshotTime?: string}
# --streamingBuffer shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
# --tableReference shape: {datasetId?: string, projectId?: string, tableId?: string}
# --timePartitioning shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
# --view shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
export def "projects-datasets-tables update-by-project-id-dataset-id-table-id" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --autodetect-schema: oneof<nothing, bool> # When true will autodetect schema, else will keep original schema
  --clone-definition: record # shape: {baseTableReference?: record, cloneTime?: string}
  --clustering: record # shape: {fields?: list<string>}
  --creation-time: string # [Output-only] The time when this table was created, in milliseconds since the epoch. (format: int64)
  --default-collation: string # [Output-only] The default collation of the table.
  --default-rounding-mode: string # [Output-only] The default rounding mode of the table.
  --description: string # [Optional] A user-friendly description of this table.
  --encryption-configuration: record # shape: {kmsKeyName?: string}
  --etag: string # [Output-only] A hash of the table metadata. Used to ensure there were no concurrent modifications to the resource when attempting an update. Not guaranteed to change when the table contents or the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  --expiration-time: string # [Optional] The time when this table expires, in milliseconds since the epoch. If not present, the table will persist indefinitely. Expired tables will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created tables. (format: int64)
  --external-data-configuration: record # shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list<string>, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list<string>}
  --friendly-name: string # [Optional] A descriptive name for this table.
  --id: string # [Output-only] An opaque ID uniquely identifying the table.
  --kind: string # [Output-only] The type of the resource. (default: bigquery#table)
  --labels: record # The labels associated with this table. You can use these to organize and group your tables. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --last-modified-time: string # [Output-only] The time when this table was last modified, in milliseconds since the epoch. (format: uint64)
  --location: string # [Output-only] The geographic location where the table resides. This value is inherited from the dataset.
  --materialized-view: record # shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
  --max-staleness: string # [Optional] Max staleness of data that could be returned when table or materialized view is queried (formatted as Google SQL Interval type). (format: byte)
  --model: record # shape: {modelOptions?: record, trainingRuns?: list}
  --num-bytes: string # [Output-only] The size of this table in bytes, excluding any data in the streaming buffer. (format: int64)
  --num-long-term-bytes: string # [Output-only] The number of bytes in the table that are considered "long-term storage". (format: int64)
  --num-physical-bytes: string # [Output-only] [TrustedTester] The physical size of this table in bytes, excluding any data in the streaming buffer. This includes compression and storage used for time travel. (format: int64)
  --num-rows: string # [Output-only] The number of rows of data in this table, excluding any data in the streaming buffer. (format: uint64)
  --num-active-logical-bytes: string # [Output-only] Number of logical bytes that are less than 90 days old. (format: int64)
  --num-active-physical-bytes: string # [Output-only] Number of physical bytes less than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-long-term-logical-bytes: string # [Output-only] Number of logical bytes that are more than 90 days old. (format: int64)
  --num-long-term-physical-bytes: string # [Output-only] Number of physical bytes more than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-partitions: string # [Output-only] The number of partitions present in the table or materialized view. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-time-travel-physical-bytes: string # [Output-only] Number of physical bytes used by time travel storage (deleted or changed data). This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-total-logical-bytes: string # [Output-only] Total number of logical bytes in the table or materialized view. (format: int64)
  --num-total-physical-bytes: string # [Output-only] The physical size of this table in bytes. This also includes storage used for time travel. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --range-partitioning: record # shape: {field?: string, range?: record}
  --require-partition-filter: oneof<nothing, bool> # [Optional] If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. (default: false)
  --schema: record # shape: {fields?: list}
  --self-link: string # [Output-only] A URL that can be used to access this resource again.
  --snapshot-definition: record # shape: {baseTableReference?: record, snapshotTime?: string}
  --streaming-buffer: record # shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
  --table-reference: record # shape: {datasetId?: string, projectId?: string, tableId?: string}
  --time-partitioning: record # shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
  --type: string # [Output-only] Describes the table type. The following values are supported: TABLE: A normal BigQuery table. VIEW: A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only table that is a copy of another table. [TrustedTester] MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table that references data stored in an external storage system, such as Google Cloud Storage. The default value is TABLE.
  --view: record # shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
]: any -> record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "autodetect_schema" $autodetect_schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), table_id: (encode-path-segment $table_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/tables/{table_id}") $qp)
  let req_body = {"cloneDefinition": $clone_definition, "clustering": $clustering, "creationTime": $creation_time, "defaultCollation": $default_collation, "defaultRoundingMode": $default_rounding_mode, "description": $description, "encryptionConfiguration": $encryption_configuration, "etag": $etag, "expirationTime": $expiration_time, "externalDataConfiguration": $external_data_configuration, "friendlyName": $friendly_name, "id": $id, "kind": $kind, "labels": $labels, "lastModifiedTime": $last_modified_time, "location": $location, "materializedView": $materialized_view, "maxStaleness": $max_staleness, "model": $model, "numBytes": $num_bytes, "numLongTermBytes": $num_long_term_bytes, "numPhysicalBytes": $num_physical_bytes, "numRows": $num_rows, "num_active_logical_bytes": $num_active_logical_bytes, "num_active_physical_bytes": $num_active_physical_bytes, "num_long_term_logical_bytes": $num_long_term_logical_bytes, "num_long_term_physical_bytes": $num_long_term_physical_bytes, "num_partitions": $num_partitions, "num_time_travel_physical_bytes": $num_time_travel_physical_bytes, "num_total_logical_bytes": $num_total_logical_bytes, "num_total_physical_bytes": $num_total_physical_bytes, "rangePartitioning": $range_partitioning, "requirePartitionFilter": $require_partition_filter, "schema": $schema, "selfLink": $self_link, "snapshotDefinition": $snapshot_definition, "streamingBuffer": $streaming_buffer, "tableReference": $table_reference, "timePartitioning": $time_partitioning, "type": $type, "view": $view} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "autodetect_schema": $autodetect_schema} | compact), body: $req_body}
}

# Updates information in an existing table. The update method replaces the entire table resource, whereas the patch method only replaces fields that are provided in the submitted table resource.
#
# PUT /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# operationId: bigquery.tables.update
# --cloneDefinition shape: {baseTableReference?: record, cloneTime?: string}
# --clustering shape: {fields?: list<string>}
# --encryptionConfiguration shape: {kmsKeyName?: string}
# --externalDataConfiguration shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list<string>, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list<string>}
# --materializedView shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
# --model shape: {modelOptions?: record, trainingRuns?: list}
# --rangePartitioning shape: {field?: string, range?: record}
# --schema shape: {fields?: list}
# --snapshotDefinition shape: {baseTableReference?: record, snapshotTime?: string}
# --streamingBuffer shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
# --tableReference shape: {datasetId?: string, projectId?: string, tableId?: string}
# --timePartitioning shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
# --view shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
export def "projects-datasets-tables update-by-project-id-dataset-id-table-id-1" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --autodetect-schema: oneof<nothing, bool> # When true will autodetect schema, else will keep original schema
  --clone-definition: record # shape: {baseTableReference?: record, cloneTime?: string}
  --clustering: record # shape: {fields?: list<string>}
  --creation-time: string # [Output-only] The time when this table was created, in milliseconds since the epoch. (format: int64)
  --default-collation: string # [Output-only] The default collation of the table.
  --default-rounding-mode: string # [Output-only] The default rounding mode of the table.
  --description: string # [Optional] A user-friendly description of this table.
  --encryption-configuration: record # shape: {kmsKeyName?: string}
  --etag: string # [Output-only] A hash of the table metadata. Used to ensure there were no concurrent modifications to the resource when attempting an update. Not guaranteed to change when the table contents or the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  --expiration-time: string # [Optional] The time when this table expires, in milliseconds since the epoch. If not present, the table will persist indefinitely. Expired tables will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created tables. (format: int64)
  --external-data-configuration: record # shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list<string>, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list<string>}
  --friendly-name: string # [Optional] A descriptive name for this table.
  --id: string # [Output-only] An opaque ID uniquely identifying the table.
  --kind: string # [Output-only] The type of the resource. (default: bigquery#table)
  --labels: record # The labels associated with this table. You can use these to organize and group your tables. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --last-modified-time: string # [Output-only] The time when this table was last modified, in milliseconds since the epoch. (format: uint64)
  --location: string # [Output-only] The geographic location where the table resides. This value is inherited from the dataset.
  --materialized-view: record # shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
  --max-staleness: string # [Optional] Max staleness of data that could be returned when table or materialized view is queried (formatted as Google SQL Interval type). (format: byte)
  --model: record # shape: {modelOptions?: record, trainingRuns?: list}
  --num-bytes: string # [Output-only] The size of this table in bytes, excluding any data in the streaming buffer. (format: int64)
  --num-long-term-bytes: string # [Output-only] The number of bytes in the table that are considered "long-term storage". (format: int64)
  --num-physical-bytes: string # [Output-only] [TrustedTester] The physical size of this table in bytes, excluding any data in the streaming buffer. This includes compression and storage used for time travel. (format: int64)
  --num-rows: string # [Output-only] The number of rows of data in this table, excluding any data in the streaming buffer. (format: uint64)
  --num-active-logical-bytes: string # [Output-only] Number of logical bytes that are less than 90 days old. (format: int64)
  --num-active-physical-bytes: string # [Output-only] Number of physical bytes less than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-long-term-logical-bytes: string # [Output-only] Number of logical bytes that are more than 90 days old. (format: int64)
  --num-long-term-physical-bytes: string # [Output-only] Number of physical bytes more than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-partitions: string # [Output-only] The number of partitions present in the table or materialized view. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-time-travel-physical-bytes: string # [Output-only] Number of physical bytes used by time travel storage (deleted or changed data). This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-total-logical-bytes: string # [Output-only] Total number of logical bytes in the table or materialized view. (format: int64)
  --num-total-physical-bytes: string # [Output-only] The physical size of this table in bytes. This also includes storage used for time travel. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --range-partitioning: record # shape: {field?: string, range?: record}
  --require-partition-filter: oneof<nothing, bool> # [Optional] If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. (default: false)
  --schema: record # shape: {fields?: list}
  --self-link: string # [Output-only] A URL that can be used to access this resource again.
  --snapshot-definition: record # shape: {baseTableReference?: record, snapshotTime?: string}
  --streaming-buffer: record # shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
  --table-reference: record # shape: {datasetId?: string, projectId?: string, tableId?: string}
  --time-partitioning: record # shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
  --type: string # [Output-only] Describes the table type. The following values are supported: TABLE: A normal BigQuery table. VIEW: A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only table that is a copy of another table. [TrustedTester] MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table that references data stored in an external storage system, such as Google Cloud Storage. The default value is TABLE.
  --view: record # shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
]: any -> record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "autodetect_schema" $autodetect_schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), table_id: (encode-path-segment $table_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/tables/{table_id}") $qp)
  let req_body = {"cloneDefinition": $clone_definition, "clustering": $clustering, "creationTime": $creation_time, "defaultCollation": $default_collation, "defaultRoundingMode": $default_rounding_mode, "description": $description, "encryptionConfiguration": $encryption_configuration, "etag": $etag, "expirationTime": $expiration_time, "externalDataConfiguration": $external_data_configuration, "friendlyName": $friendly_name, "id": $id, "kind": $kind, "labels": $labels, "lastModifiedTime": $last_modified_time, "location": $location, "materializedView": $materialized_view, "maxStaleness": $max_staleness, "model": $model, "numBytes": $num_bytes, "numLongTermBytes": $num_long_term_bytes, "numPhysicalBytes": $num_physical_bytes, "numRows": $num_rows, "num_active_logical_bytes": $num_active_logical_bytes, "num_active_physical_bytes": $num_active_physical_bytes, "num_long_term_logical_bytes": $num_long_term_logical_bytes, "num_long_term_physical_bytes": $num_long_term_physical_bytes, "num_partitions": $num_partitions, "num_time_travel_physical_bytes": $num_time_travel_physical_bytes, "num_total_logical_bytes": $num_total_logical_bytes, "num_total_physical_bytes": $num_total_physical_bytes, "rangePartitioning": $range_partitioning, "requirePartitionFilter": $require_partition_filter, "schema": $schema, "selfLink": $self_link, "snapshotDefinition": $snapshot_definition, "streamingBuffer": $streaming_buffer, "tableReference": $table_reference, "timePartitioning": $time_partitioning, "type": $type, "view": $view} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "autodetect_schema": $autodetect_schema} | compact), body: $req_body}
}

# Retrieves table data from a specified set of rows. Requires the READER dataset role.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables/{tableId}/data
# operationId: bigquery.tabledata.list
export def "projects-datasets-tables-data list" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of results to return
  --page-token: string # Page token, returned by a previous call, identifying the result set
  --selected-fields: string # List of fields to return (comma-separated). If unspecified, all fields are returned
  --start-index: string # Zero-based index of the starting row to read
]: nothing -> record<etag: string, kind: string, pageToken: string, rows: table<f: list>, totalRows: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "selectedFields" $selected_fields "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), table_id: (encode-path-segment $table_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/tables/{table_id}/data") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token, "selectedFields": $selected_fields, "startIndex": $start_index} | compact), body: null}
}

# Streams data into BigQuery one record at a time without needing to run a load job. Requires the WRITER dataset role.
#
# POST /projects/{projectId}/datasets/{datasetId}/tables/{tableId}/insertAll
# operationId: bigquery.tabledata.insertAll
# --rows item shape: {insertId?: string, json?: record}
export def "projects-datasets-tables-insert-all create" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-unknown-values: oneof<nothing, bool> # [Optional] Accept rows that contain values that do not match the schema. The unknown values are ignored. Default is false, which treats unknown values as errors.
  --kind: string # The resource type of the response. (default: bigquery#tableDataInsertAllRequest)
  --rows: list # The rows to insert. — item shape: {insertId?: string, json?: record}
  --skip-invalid-rows: oneof<nothing, bool> # [Optional] Insert all valid rows of a request, even if invalid rows exist. The default value is false, which causes the entire request to fail if any invalid rows exist.
  --template-suffix: string # If specified, treats the destination table as a base template, and inserts the rows into an instance table named "{destination}{templateSuffix}". BigQuery will manage creation of the instance table, using the schema of the base template table. See https://cloud.google.com/bigquery/streaming-data-into-bigquery#template-tables for considerations when working with templates tables.
]: any -> record<insertErrors: table<errors: list, index: int>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), table_id: (encode-path-segment $table_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/tables/{table_id}/insertAll") $qp)
  let req_body = {"ignoreUnknownValues": $ignore_unknown_values, "kind": $kind, "rows": $rows, "skipInvalidRows": $skip_invalid_rows, "templateSuffix": $template_suffix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Lists all row access policies on the specified table.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables/{tableId}/rowAccessPolicies
# operationId: bigquery.rowAccessPolicies.list
export def "projects-datasets-tables-row-access-policies list" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --page-size: int # The maximum number of results to return in a single response page. Leverage the page tokens to iterate through the entire collection.
  --page-token: string # Page token, returned by a previous call, to request the next page of results.
]: nothing -> record<nextPageToken: string, rowAccessPolicies: table<creationTime: string, etag: string, filterPredicate: string, lastModifiedTime: string, rowAccessPolicyReference: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), dataset_id: (encode-path-segment $dataset_id), table_id: (encode-path-segment $table_id)} | format pattern "/projects/{project_id}/datasets/{dataset_id}/tables/{table_id}/rowAccessPolicies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Lists all jobs that you started in the specified project. Job information is available for a six month period after creation. The job list is sorted in reverse chronological order, by job creation time. Requires the Can View project role, or the Is Owner project role if you set the allUsers property.
#
# GET /projects/{projectId}/jobs
# operationId: bigquery.jobs.list
export def "projects-jobs list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --all-users: oneof<nothing, bool> # Whether to display jobs owned by all users in the project. Default false
  --max-creation-time: string # Max value for job creation time, in milliseconds since the POSIX epoch. If set, only jobs created before or at this timestamp are returned
  --max-results: int # Maximum number of results to return
  --min-creation-time: string # Min value for job creation time, in milliseconds since the POSIX epoch. If set, only jobs created after or at this timestamp are returned
  --page-token: string # Page token, returned by a previous call, to request the next page of results
  --parent-job-id: string # If set, retrieves only jobs whose parent is this job. Otherwise, retrieves only jobs which have no parent
  --projection: string@projection-completer # Restrict information returned to a set of selected fields
  --state-filter: list<string> # Filter for job state
]: nothing -> record<etag: string, jobs: table<configuration: record, errorResult: record, id: string, jobReference: record, kind: string, state: string, statistics: record, status: record, user_email: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "allUsers" $all_users "scalar") (serialize-qp "maxCreationTime" $max_creation_time "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "minCreationTime" $min_creation_time "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "parentJobId" $parent_job_id "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "stateFilter" $state_filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "allUsers": $all_users, "maxCreationTime": $max_creation_time, "maxResults": $max_results, "minCreationTime": $min_creation_time, "pageToken": $page_token, "parentJobId": $parent_job_id, "projection": $projection, "stateFilter": $state_filter} | compact), body: null}
}

# Starts a new asynchronous job. Requires the Can View project role.
#
# POST /projects/{projectId}/jobs
# operationId: bigquery.jobs.insert
export def "projects-jobs create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body: any
]: any -> record<configuration: record<copy: record<createDisposition: string, destinationEncryptionConfiguration: record, destinationExpirationTime: any, destinationTable: record, operationType: string, sourceTable: record, sourceTables: list, writeDisposition: string>, dryRun: bool, extract: record<compression: string, destinationFormat: string, destinationUri: string, destinationUris: list, fieldDelimiter: string, printHeader: bool, sourceModel: record, sourceTable: record, useAvroLogicalTypes: bool>, jobTimeoutMs: string, jobType: string, labels: record, load: record<allowJaggedRows: bool, allowQuotedNewlines: bool, autodetect: bool, clustering: record, connectionProperties: list, createDisposition: string, createSession: bool, decimalTargetTypes: list, destinationEncryptionConfiguration: record, destinationTable: record, destinationTableProperties: record, encoding: string, fieldDelimiter: string, hivePartitioningOptions: record, ignoreUnknownValues: bool, jsonExtension: string, maxBadRecords: int, nullMarker: string, parquetOptions: record, preserveAsciiControlCharacters: bool, projectionFields: list, quote: string, rangePartitioning: record, referenceFileSchemaUri: string, schema: record, schemaInline: string, schemaInlineFormat: string, schemaUpdateOptions: list, skipLeadingRows: int, sourceFormat: string, sourceUris: list, timePartitioning: record, useAvroLogicalTypes: bool, writeDisposition: string>, query: record<allowLargeResults: bool, clustering: record, connectionProperties: list, continuous: bool, createDisposition: string, createSession: bool, defaultDataset: record, destinationEncryptionConfiguration: record, destinationTable: record, flattenResults: bool, maximumBillingTier: int, maximumBytesBilled: string, parameterMode: string, preserveNulls: bool, priority: string, query: string, queryParameters: list, rangePartitioning: record, schemaUpdateOptions: list, tableDefinitions: record, timePartitioning: record, useLegacySql: bool, useQueryCache: bool, userDefinedFunctionResources: list, writeDisposition: string>>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record<copied_logical_bytes: string, copied_rows: string>, creationTime: string, dataMaskingStatistics: record<dataMaskingApplied: bool>, endTime: string, extract: record<destinationUriFileCounts: list, inputBytes: string>, load: record<badRecords: string, inputFileBytes: string, inputFiles: string, outputBytes: string, outputRows: string>, numChildJobs: string, parentJobId: string, query: record<biEngineStatistics: record, billingTier: int, cacheHit: bool, ddlAffectedRowAccessPolicyCount: string, ddlDestinationTable: record, ddlOperationPerformed: string, ddlTargetDataset: record, ddlTargetRoutine: record, ddlTargetRowAccessPolicy: record, ddlTargetTable: record, dmlStats: record, estimatedBytesProcessed: string, mlStatistics: record, modelTraining: record, modelTrainingCurrentIteration: int, modelTrainingExpectedTotalIteration: string, numDmlAffectedRows: string, queryPlan: list, referencedRoutines: list, referencedTables: list, reservationUsage: list, schema: record, searchStatistics: record, sparkStatistics: record, statementType: string, timeline: list, totalBytesBilled: string, totalBytesProcessed: string, totalBytesProcessedAccuracy: string, totalPartitionsProcessed: string, totalSlotMs: string, transferredBytes: string, undeclaredQueryParameters: list>, quotaDeferments: list<string>, reservationUsage: list<record>, reservation_id: string, rowLevelSecurityStatistics: record<rowLevelSecurityApplied: bool>, scriptStatistics: record<evaluationKind: string, stackFrames: list>, sessionInfo: record<sessionId: string>, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record<transactionId: string>>, status: record<errorResult: record<debugInfo: string, location: string, message: string, reason: string>, errors: list<record>, state: string>, user_email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/jobs") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Returns information about a specific job. Job information is available for a six month period after creation. Requires that you're the person who ran the job, or have the Is Owner project role.
#
# GET /projects/{projectId}/jobs/{jobId}
# operationId: bigquery.jobs.get
export def "projects-jobs get" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location of the job. Required except for US and EU. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
]: nothing -> record<configuration: record<copy: record<createDisposition: string, destinationEncryptionConfiguration: record, destinationExpirationTime: any, destinationTable: record, operationType: string, sourceTable: record, sourceTables: list, writeDisposition: string>, dryRun: bool, extract: record<compression: string, destinationFormat: string, destinationUri: string, destinationUris: list, fieldDelimiter: string, printHeader: bool, sourceModel: record, sourceTable: record, useAvroLogicalTypes: bool>, jobTimeoutMs: string, jobType: string, labels: record, load: record<allowJaggedRows: bool, allowQuotedNewlines: bool, autodetect: bool, clustering: record, connectionProperties: list, createDisposition: string, createSession: bool, decimalTargetTypes: list, destinationEncryptionConfiguration: record, destinationTable: record, destinationTableProperties: record, encoding: string, fieldDelimiter: string, hivePartitioningOptions: record, ignoreUnknownValues: bool, jsonExtension: string, maxBadRecords: int, nullMarker: string, parquetOptions: record, preserveAsciiControlCharacters: bool, projectionFields: list, quote: string, rangePartitioning: record, referenceFileSchemaUri: string, schema: record, schemaInline: string, schemaInlineFormat: string, schemaUpdateOptions: list, skipLeadingRows: int, sourceFormat: string, sourceUris: list, timePartitioning: record, useAvroLogicalTypes: bool, writeDisposition: string>, query: record<allowLargeResults: bool, clustering: record, connectionProperties: list, continuous: bool, createDisposition: string, createSession: bool, defaultDataset: record, destinationEncryptionConfiguration: record, destinationTable: record, flattenResults: bool, maximumBillingTier: int, maximumBytesBilled: string, parameterMode: string, preserveNulls: bool, priority: string, query: string, queryParameters: list, rangePartitioning: record, schemaUpdateOptions: list, tableDefinitions: record, timePartitioning: record, useLegacySql: bool, useQueryCache: bool, userDefinedFunctionResources: list, writeDisposition: string>>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record<copied_logical_bytes: string, copied_rows: string>, creationTime: string, dataMaskingStatistics: record<dataMaskingApplied: bool>, endTime: string, extract: record<destinationUriFileCounts: list, inputBytes: string>, load: record<badRecords: string, inputFileBytes: string, inputFiles: string, outputBytes: string, outputRows: string>, numChildJobs: string, parentJobId: string, query: record<biEngineStatistics: record, billingTier: int, cacheHit: bool, ddlAffectedRowAccessPolicyCount: string, ddlDestinationTable: record, ddlOperationPerformed: string, ddlTargetDataset: record, ddlTargetRoutine: record, ddlTargetRowAccessPolicy: record, ddlTargetTable: record, dmlStats: record, estimatedBytesProcessed: string, mlStatistics: record, modelTraining: record, modelTrainingCurrentIteration: int, modelTrainingExpectedTotalIteration: string, numDmlAffectedRows: string, queryPlan: list, referencedRoutines: list, referencedTables: list, reservationUsage: list, schema: record, searchStatistics: record, sparkStatistics: record, statementType: string, timeline: list, totalBytesBilled: string, totalBytesProcessed: string, totalBytesProcessedAccuracy: string, totalPartitionsProcessed: string, totalSlotMs: string, transferredBytes: string, undeclaredQueryParameters: list>, quotaDeferments: list<string>, reservationUsage: list<record>, reservation_id: string, rowLevelSecurityStatistics: record<rowLevelSecurityApplied: bool>, scriptStatistics: record<evaluationKind: string, stackFrames: list>, sessionInfo: record<sessionId: string>, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record<transactionId: string>>, status: record<errorResult: record<debugInfo: string, location: string, message: string, reason: string>, errors: list<record>, state: string>, user_email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/projects/{project_id}/jobs/{job_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "location": $location} | compact), body: null}
}

# Requests that a job be cancelled. This call will return immediately, and the client will need to poll for the job status to see if the cancel completed successfully. Cancelled jobs may still incur costs.
#
# POST /projects/{projectId}/jobs/{jobId}/cancel
# operationId: bigquery.jobs.cancel
export def "projects-jobs-cancel cancel" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location of the job. Required except for US and EU. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
]: nothing -> record<job: record<configuration: record<copy: record, dryRun: bool, extract: record, jobTimeoutMs: string, jobType: string, labels: record, load: record, query: record>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record, creationTime: string, dataMaskingStatistics: record, endTime: string, extract: record, load: record, numChildJobs: string, parentJobId: string, query: record, quotaDeferments: list, reservationUsage: list, reservation_id: string, rowLevelSecurityStatistics: record, scriptStatistics: record, sessionInfo: record, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record>, status: record<errorResult: record, errors: list, state: string>, user_email: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/projects/{project_id}/jobs/{job_id}/cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "location": $location} | compact), body: null}
}

# Requests the deletion of the metadata of a job. This call returns when the job's metadata is deleted.
#
# DELETE /projects/{projectId}/jobs/{jobId}/delete
# operationId: bigquery.jobs.delete
export def "projects-jobs-delete delete" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location of the job. Required. See details at: https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/projects/{project_id}/jobs/{job_id}/delete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "location": $location} | compact), body: null}
}

# Runs a BigQuery SQL query synchronously and returns query results if the query completes within a specified timeout.
#
# POST /projects/{projectId}/queries
# operationId: bigquery.jobs.query
# --connectionProperties item shape: {key?: string, value?: string}
# --defaultDataset shape: {datasetId?: string, projectId?: string}
# --queryParameters item shape: {name?: string, parameterType?: record, parameterValue?: record}
export def "projects-queries list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --connection-properties: list # Connection properties. — item shape: {key?: string, value?: string}
  --continuous: oneof<nothing, bool> # [Optional] Specifies whether the query should be executed as a continuous query. The default value is false.
  --create-session: oneof<nothing, bool> # If true, creates a new session, where session id will be a server generated random id. If false, runs query with an existing session_id passed in ConnectionProperty, otherwise runs query in non-session mode.
  --default-dataset: record # shape: {datasetId?: string, projectId?: string}
  --body-dry-run: oneof<nothing, bool> # [Optional] If set to true, BigQuery doesn't run the job. Instead, if the query is valid, BigQuery returns statistics about the job such as how many bytes would be processed. If the query is invalid, an error returns. The default value is false.
  --kind: string # The resource type of the request. (default: bigquery#queryRequest)
  --labels: record # The labels associated with this job. You can use these to organize and group your jobs. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --location: string # The geographic location where the job should run. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  --max-results: int # [Optional] The maximum number of rows of data to return per page of results. Setting this flag to a small value such as 1000 and then paging through results might improve reliability when the query result set is large. In addition to this limit, responses are also limited to 10 MB. By default, there is no maximum row count, and only the byte limit applies. (format: uint32)
  --maximum-bytes-billed: string # [Optional] Limits the bytes billed for this job. Queries that will have bytes billed beyond this limit will fail (without incurring a charge). If unspecified, this will be set to your project default. (format: int64)
  --parameter-mode: string # Standard SQL only. Set to POSITIONAL to use positional (?) query parameters or to NAMED to use named (@myparam) query parameters in this query.
  --preserve-nulls: oneof<nothing, bool> # [Deprecated] This property is deprecated.
  --query: string # [Required] A query string, following the BigQuery query syntax, of the query to execute. Example: "SELECT count(f1) FROM [myProjectId:myDatasetId.myTableId]".
  --query-parameters: list # Query parameters for Standard SQL queries. — item shape: {name?: string, parameterType?: record, parameterValue?: record}
  --request-id: string # A unique user provided identifier to ensure idempotent behavior for queries. Note that this is different from the job_id. It has the following properties: 1. It is case-sensitive, limited to up to 36 ASCII characters. A UUID is recommended. 2. Read only queries can ignore this token since they are nullipotent by definition. 3. For the purposes of idempotency ensured by the request_id, a request is considered duplicate of another only if they have the same request_id and are actually duplicates. When determining whether a request is a duplicate of the previous request, all parameters in the request that may affect the behavior are considered. For example, query, connection_properties, query_parameters, use_legacy_sql are parameters that affect the result and are considered when determining whether a request is a duplicate, but properties like timeout_ms don't affect the result and are thus not considered. Dry run query requests are never considered duplicate of another request. 4. When a duplicate mutating query request is detected, it returns: a. the results of the mutation if it completes successfully within the timeout. b. the running operation if it is still in progress at the end of the timeout. 5. Its lifetime is limited to 15 minutes. In other words, if two requests are sent with the same request_id, but more than 15 minutes apart, idempotency is not guaranteed.
  --timeout-ms: int # [Optional] How long to wait for the query to complete, in milliseconds, before the request times out and returns. Note that this is only a timeout for the request, not the query. If the query takes longer to run than the timeout value, the call returns without any results and with the 'jobComplete' flag set to false. You can call GetQueryResults() to wait for the query to complete and read the results. The default value is 10000 milliseconds (10 seconds). (format: uint32)
  --use-legacy-sql: oneof<nothing, bool> # Specifies whether to use BigQuery's legacy SQL dialect for this query. The default value is true. If set to false, the query will use BigQuery's standard SQL: https://cloud.google.com/bigquery/sql-reference/ When useLegacySql is set to false, the value of flattenResults is ignored; query will be run as if flattenResults is false. (default: true)
  --use-query-cache: oneof<nothing, bool> # [Optional] Whether to look for the result in the query cache. The query cache is a best-effort cache that will be flushed whenever tables in the query are modified. The default value is true. (default: true)
]: any -> record<cacheHit: bool, dmlStats: record<deletedRowCount: string, insertedRowCount: string, updatedRowCount: string>, errors: table<debugInfo: string, location: string, message: string, reason: string>, jobComplete: bool, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, numDmlAffectedRows: string, pageToken: string, rows: table<f: list>, schema: record<fields: list<record>>, sessionInfo: record<sessionId: string>, totalBytesProcessed: string, totalRows: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/queries") $qp)
  let req_body = {"connectionProperties": $connection_properties, "continuous": $continuous, "createSession": $create_session, "defaultDataset": $default_dataset, "dryRun": $body_dry_run, "kind": $kind, "labels": $labels, "location": $location, "maxResults": $max_results, "maximumBytesBilled": $maximum_bytes_billed, "parameterMode": $parameter_mode, "preserveNulls": $preserve_nulls, "query": $query, "queryParameters": $query_parameters, "requestId": $request_id, "timeoutMs": $timeout_ms, "useLegacySql": $use_legacy_sql, "useQueryCache": $use_query_cache} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Retrieves the results of a query job.
#
# GET /projects/{projectId}/queries/{jobId}
# operationId: bigquery.jobs.getQueryResults
export def "projects-queries get-list-results" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location where the job should run. Required except for US and EU. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  --max-results: int # Maximum number of results to read
  --page-token: string # Page token, returned by a previous call, to request the next page of results
  --start-index: string # Zero-based index of the starting row
  --timeout-ms: int # How long to wait for the query to complete, in milliseconds, before returning. Default is 10 seconds. If the timeout passes before the job completes, the 'jobComplete' field in the response will be false
]: nothing -> record<cacheHit: bool, errors: table<debugInfo: string, location: string, message: string, reason: string>, etag: string, jobComplete: bool, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, numDmlAffectedRows: string, pageToken: string, rows: table<f: list>, schema: record<fields: list<record>>, totalBytesProcessed: string, totalRows: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "startIndex" $start_index "scalar") (serialize-qp "timeoutMs" $timeout_ms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/projects/{project_id}/queries/{job_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "location": $location, "maxResults": $max_results, "pageToken": $page_token, "startIndex": $start_index, "timeoutMs": $timeout_ms} | compact), body: null}
}

# Returns the email address of the service account for your project used for interactions with Google Cloud KMS.
#
# GET /projects/{projectId}/serviceAccount
# operationId: bigquery.projects.getServiceAccount
export def "projects-service-account get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<email: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/serviceAccount") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# POST /{resource}:getIamPolicy
# operationId: bigquery.tables.getIamPolicy
# --options shape: {requestedPolicyVersion?: int}
export def "tables get-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --options: record # Encapsulates settings provided to GetIamPolicy. — shape: {requestedPolicyVersion?: int}
]: any -> record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/{resource}:getIamPolicy") $qp)
  let req_body = {"options": $options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Sets the access control policy on the specified resource. Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`, and `PERMISSION_DENIED` errors.
#
# POST /{resource}:setIamPolicy
# operationId: bigquery.tables.setIamPolicy
# --policy shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
export def "tables update-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: `paths: "bindings, etag"` (format: google-fieldmask)
]: any -> record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/{resource}:setIamPolicy") $qp)
  let req_body = {"policy": $policy, "updateMask": $update_mask} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a `NOT_FOUND` error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /{resource}:testIamPermissions
# operationId: bigquery.tables.testIamPermissions
export def "tables test-iam-permissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> record<permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/{resource}:testIamPermissions") $qp)
  let req_body = {"permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}
