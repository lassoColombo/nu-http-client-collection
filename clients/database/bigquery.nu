# Auto-generated client for BigQuery API vv2
# Source: https://api.apis.guru/v2/specs/googleapis.com/bigquery/v2/openapi.json
# Auth: --token flag or $env.BIGQUERY_API_TOKEN

const BASE_URL = "https://bigquery.googleapis.com/bigquery/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BIGQUERY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://bigquery.googleapis.com/bigquery/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def determinismLevel-completer [] { ["DETERMINISM_LEVEL_UNSPECIFIED" "DETERMINISTIC" "NOT_DETERMINISTIC"] }
def language-completer [] { ["JAVA" "JAVASCRIPT" "LANGUAGE_UNSPECIFIED" "PYTHON" "SCALA" "SQL"] }
def routineType-completer [] { ["PROCEDURE" "ROUTINE_TYPE_UNSPECIFIED" "SCALAR_FUNCTION" "TABLE_VALUED_FUNCTION"] }
def view-completer [] { ["BASIC" "FULL" "STORAGE_STATS" "TABLE_METADATA_VIEW_UNSPECIFIED"] }
def projection-completer [] { ["full" "minimal"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "projects bigqueryprojectslist" } } | get name | first)
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
export def "projects bigqueryprojectslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --maxResults: int # Maximum number of results to return
  --pageToken: string # Page token, returned by a previous call, to request the next page of results
]: nothing -> record<etag: string, kind: string, nextPageToken: string, projects: table<friendlyName: string, id: string, kind: string, numericId: string, projectReference: record>, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all datasets in the specified project to which you have been granted the READER dataset role.
#
# GET /projects/{projectId}/datasets
# operationId: bigquery.datasets.list
export def "projects-datasets bigquerydatasetslist" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --all: oneof<nothing, bool> # Whether to list all datasets, including hidden ones
  --filter: string # An expression for filtering the results of the request by label. The syntax is "labels.<name>[:<value>]". Multiple filters can be ANDed together by connecting with a space. Example: "labels.department:receiving labels.active". See Filtering datasets using labels for details.
  --maxResults: int # The maximum number of results to return
  --pageToken: string # Page token, returned by a previous call, to request the next page of results
]: nothing -> record<datasets: table<datasetReference: record, friendlyName: string, id: string, kind: string, labels: record, location: string>, etag: string, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new empty dataset.
#
# POST /projects/{projectId}/datasets
# operationId: bigquery.datasets.insert
# --access item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
# --datasetReference shape: {datasetId?: string, projectId?: string}
# --defaultEncryptionConfiguration shape: {kmsKeyName?: string}
# --tags item shape: {tagKey?: string, tagValue?: string}
export def "projects-datasets bigquerydatasetsinsert" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --access: list # [Optional] An array of objects that define dataset access for one or more entities. You can set this property when inserting or updating a dataset in order to control who is allowed to access the data. If unspecified at dataset creation time, BigQuery adds default dataset access for the following entities: access.specialGroup: projectReaders; access.role: READER; access.specialGroup: projectWriters; access.role: WRITER; access.specialGroup: projectOwners; access.role: OWNER; access.userByEmail: [dataset creator email]; access.role: OWNER; — item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
  --creationTime: string # [Output-only] The time when this dataset was created, in milliseconds since the epoch. (format: int64)
  --datasetReference: record # shape: {datasetId?: string, projectId?: string}
  --defaultCollation: string # [Output-only] The default collation of the dataset.
  --defaultEncryptionConfiguration: record # shape: {kmsKeyName?: string}
  --defaultPartitionExpirationMs: string # [Optional] The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. Setting this property overrides the use of defaultTableExpirationMs for partitioned tables: only one of defaultTableExpirationMs and defaultPartitionExpirationMs will be used for any new partitioned table. If you provide an explicit timePartitioning.expirationMs when creating or updating a partitioned table, that value takes precedence over the default partition expiration time indicated by this property. (format: int64)
  --defaultRoundingMode: string # [Output-only] The default rounding mode of the dataset.
  --defaultTableExpirationMs: string # [Optional] The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. (format: int64)
  --description: string # [Optional] A user-friendly description of the dataset.
  --etag: string # [Output-only] A hash of the resource.
  --friendlyName: string # [Optional] A descriptive name for the dataset.
  --id: string # [Output-only] The fully-qualified unique name of the dataset in the format projectId:datasetId. The dataset name without the project name is given in the datasetId field. When creating a new dataset, leave this field blank, and instead specify the datasetId field.
  --isCaseInsensitive: oneof<nothing, bool> # [Optional] Indicates if table names are case insensitive in the dataset.
  --kind: string # [Output-only] The resource type. (default: bigquery#dataset)
  --labels: record # The labels associated with this dataset. You can use these to organize and group your datasets. You can set this property when inserting or updating a dataset. See Creating and Updating Dataset Labels for more information.
  --lastModifiedTime: string # [Output-only] The date when this dataset or any of its tables was last modified, in milliseconds since the epoch. (format: int64)
  --location: string # The geographic location where the dataset should reside. The default value is US. See details at https://cloud.google.com/bigquery/docs/locations.
  --maxTimeTravelHours: string # [Optional] Number of hours for the max time travel for all tables in the dataset. (format: int64)
  --satisfiesPzs: oneof<nothing, bool> # [Output-only] Reserved for future use.
  --selfLink: string # [Output-only] A URL that can be used to access the resource again. You can use this URL in Get or Update requests to the resource.
  --storageBillingModel: string # [Optional] Storage billing model to be used for all tables in the dataset. Can be set to PHYSICAL. Default is LOGICAL.
  --tags: list # [Optional]The tags associated with this dataset. Tag keys are globally unique. — item shape: {tagKey?: string, tagValue?: string}
]: any -> record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets" $qp)
  let body = {access: $access, creationTime: $creationTime, datasetReference: $datasetReference, defaultCollation: $defaultCollation, defaultEncryptionConfiguration: $defaultEncryptionConfiguration, defaultPartitionExpirationMs: $defaultPartitionExpirationMs, defaultRoundingMode: $defaultRoundingMode, defaultTableExpirationMs: $defaultTableExpirationMs, description: $description, etag: $etag, friendlyName: $friendlyName, id: $id, isCaseInsensitive: $isCaseInsensitive, kind: $kind, labels: $labels, lastModifiedTime: $lastModifiedTime, location: $location, maxTimeTravelHours: $maxTimeTravelHours, satisfiesPzs: $satisfiesPzs, selfLink: $selfLink, storageBillingModel: $storageBillingModel, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the dataset specified by the datasetId value. Before you can delete a dataset, you must delete all its tables, either manually or by specifying deleteContents. Immediately after deletion, you can create another dataset with the same name.
#
# DELETE /projects/{projectId}/datasets/{datasetId}
# operationId: bigquery.datasets.delete
export def "projects-datasets bigquerydatasetsdelete" [
  projectId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --deleteContents: oneof<nothing, bool> # If True, delete all the tables in the dataset. If False and the dataset contains tables, the request will fail. Default is False
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "deleteContents" $deleteContents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the dataset specified by datasetID.
#
# GET /projects/{projectId}/datasets/{datasetId}
# operationId: bigquery.datasets.get
export def "projects-datasets bigquerydatasetsget" [
  projectId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates information in an existing dataset. The update method replaces the entire dataset resource, whereas the patch method only replaces fields that are provided in the submitted dataset resource. This method supports patch semantics.
#
# PATCH /projects/{projectId}/datasets/{datasetId}
# operationId: bigquery.datasets.patch
# --access item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
# --datasetReference shape: {datasetId?: string, projectId?: string}
# --defaultEncryptionConfiguration shape: {kmsKeyName?: string}
# --tags item shape: {tagKey?: string, tagValue?: string}
export def "projects-datasets bigquerydatasetspatch" [
  projectId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --access: list # [Optional] An array of objects that define dataset access for one or more entities. You can set this property when inserting or updating a dataset in order to control who is allowed to access the data. If unspecified at dataset creation time, BigQuery adds default dataset access for the following entities: access.specialGroup: projectReaders; access.role: READER; access.specialGroup: projectWriters; access.role: WRITER; access.specialGroup: projectOwners; access.role: OWNER; access.userByEmail: [dataset creator email]; access.role: OWNER; — item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
  --creationTime: string # [Output-only] The time when this dataset was created, in milliseconds since the epoch. (format: int64)
  --datasetReference: record # shape: {datasetId?: string, projectId?: string}
  --defaultCollation: string # [Output-only] The default collation of the dataset.
  --defaultEncryptionConfiguration: record # shape: {kmsKeyName?: string}
  --defaultPartitionExpirationMs: string # [Optional] The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. Setting this property overrides the use of defaultTableExpirationMs for partitioned tables: only one of defaultTableExpirationMs and defaultPartitionExpirationMs will be used for any new partitioned table. If you provide an explicit timePartitioning.expirationMs when creating or updating a partitioned table, that value takes precedence over the default partition expiration time indicated by this property. (format: int64)
  --defaultRoundingMode: string # [Output-only] The default rounding mode of the dataset.
  --defaultTableExpirationMs: string # [Optional] The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. (format: int64)
  --description: string # [Optional] A user-friendly description of the dataset.
  --etag: string # [Output-only] A hash of the resource.
  --friendlyName: string # [Optional] A descriptive name for the dataset.
  --id: string # [Output-only] The fully-qualified unique name of the dataset in the format projectId:datasetId. The dataset name without the project name is given in the datasetId field. When creating a new dataset, leave this field blank, and instead specify the datasetId field.
  --isCaseInsensitive: oneof<nothing, bool> # [Optional] Indicates if table names are case insensitive in the dataset.
  --kind: string # [Output-only] The resource type. (default: bigquery#dataset)
  --labels: record # The labels associated with this dataset. You can use these to organize and group your datasets. You can set this property when inserting or updating a dataset. See Creating and Updating Dataset Labels for more information.
  --lastModifiedTime: string # [Output-only] The date when this dataset or any of its tables was last modified, in milliseconds since the epoch. (format: int64)
  --location: string # The geographic location where the dataset should reside. The default value is US. See details at https://cloud.google.com/bigquery/docs/locations.
  --maxTimeTravelHours: string # [Optional] Number of hours for the max time travel for all tables in the dataset. (format: int64)
  --satisfiesPzs: oneof<nothing, bool> # [Output-only] Reserved for future use.
  --selfLink: string # [Output-only] A URL that can be used to access the resource again. You can use this URL in Get or Update requests to the resource.
  --storageBillingModel: string # [Optional] Storage billing model to be used for all tables in the dataset. Can be set to PHYSICAL. Default is LOGICAL.
  --tags: list # [Optional]The tags associated with this dataset. Tag keys are globally unique. — item shape: {tagKey?: string, tagValue?: string}
]: any -> record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)" $qp)
  let body = {access: $access, creationTime: $creationTime, datasetReference: $datasetReference, defaultCollation: $defaultCollation, defaultEncryptionConfiguration: $defaultEncryptionConfiguration, defaultPartitionExpirationMs: $defaultPartitionExpirationMs, defaultRoundingMode: $defaultRoundingMode, defaultTableExpirationMs: $defaultTableExpirationMs, description: $description, etag: $etag, friendlyName: $friendlyName, id: $id, isCaseInsensitive: $isCaseInsensitive, kind: $kind, labels: $labels, lastModifiedTime: $lastModifiedTime, location: $location, maxTimeTravelHours: $maxTimeTravelHours, satisfiesPzs: $satisfiesPzs, selfLink: $selfLink, storageBillingModel: $storageBillingModel, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates information in an existing dataset. The update method replaces the entire dataset resource, whereas the patch method only replaces fields that are provided in the submitted dataset resource.
#
# PUT /projects/{projectId}/datasets/{datasetId}
# operationId: bigquery.datasets.update
# --access item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
# --datasetReference shape: {datasetId?: string, projectId?: string}
# --defaultEncryptionConfiguration shape: {kmsKeyName?: string}
# --tags item shape: {tagKey?: string, tagValue?: string}
export def "projects-datasets bigquerydatasetsupdate" [
  projectId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --access: list # [Optional] An array of objects that define dataset access for one or more entities. You can set this property when inserting or updating a dataset in order to control who is allowed to access the data. If unspecified at dataset creation time, BigQuery adds default dataset access for the following entities: access.specialGroup: projectReaders; access.role: READER; access.specialGroup: projectWriters; access.role: WRITER; access.specialGroup: projectOwners; access.role: OWNER; access.userByEmail: [dataset creator email]; access.role: OWNER; — item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
  --creationTime: string # [Output-only] The time when this dataset was created, in milliseconds since the epoch. (format: int64)
  --datasetReference: record # shape: {datasetId?: string, projectId?: string}
  --defaultCollation: string # [Output-only] The default collation of the dataset.
  --defaultEncryptionConfiguration: record # shape: {kmsKeyName?: string}
  --defaultPartitionExpirationMs: string # [Optional] The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. Setting this property overrides the use of defaultTableExpirationMs for partitioned tables: only one of defaultTableExpirationMs and defaultPartitionExpirationMs will be used for any new partitioned table. If you provide an explicit timePartitioning.expirationMs when creating or updating a partitioned table, that value takes precedence over the default partition expiration time indicated by this property. (format: int64)
  --defaultRoundingMode: string # [Output-only] The default rounding mode of the dataset.
  --defaultTableExpirationMs: string # [Optional] The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. (format: int64)
  --description: string # [Optional] A user-friendly description of the dataset.
  --etag: string # [Output-only] A hash of the resource.
  --friendlyName: string # [Optional] A descriptive name for the dataset.
  --id: string # [Output-only] The fully-qualified unique name of the dataset in the format projectId:datasetId. The dataset name without the project name is given in the datasetId field. When creating a new dataset, leave this field blank, and instead specify the datasetId field.
  --isCaseInsensitive: oneof<nothing, bool> # [Optional] Indicates if table names are case insensitive in the dataset.
  --kind: string # [Output-only] The resource type. (default: bigquery#dataset)
  --labels: record # The labels associated with this dataset. You can use these to organize and group your datasets. You can set this property when inserting or updating a dataset. See Creating and Updating Dataset Labels for more information.
  --lastModifiedTime: string # [Output-only] The date when this dataset or any of its tables was last modified, in milliseconds since the epoch. (format: int64)
  --location: string # The geographic location where the dataset should reside. The default value is US. See details at https://cloud.google.com/bigquery/docs/locations.
  --maxTimeTravelHours: string # [Optional] Number of hours for the max time travel for all tables in the dataset. (format: int64)
  --satisfiesPzs: oneof<nothing, bool> # [Output-only] Reserved for future use.
  --selfLink: string # [Output-only] A URL that can be used to access the resource again. You can use this URL in Get or Update requests to the resource.
  --storageBillingModel: string # [Optional] Storage billing model to be used for all tables in the dataset. Can be set to PHYSICAL. Default is LOGICAL.
  --tags: list # [Optional]The tags associated with this dataset. Tag keys are globally unique. — item shape: {tagKey?: string, tagValue?: string}
]: any -> record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)" $qp)
  let body = {access: $access, creationTime: $creationTime, datasetReference: $datasetReference, defaultCollation: $defaultCollation, defaultEncryptionConfiguration: $defaultEncryptionConfiguration, defaultPartitionExpirationMs: $defaultPartitionExpirationMs, defaultRoundingMode: $defaultRoundingMode, defaultTableExpirationMs: $defaultTableExpirationMs, description: $description, etag: $etag, friendlyName: $friendlyName, id: $id, isCaseInsensitive: $isCaseInsensitive, kind: $kind, labels: $labels, lastModifiedTime: $lastModifiedTime, location: $location, maxTimeTravelHours: $maxTimeTravelHours, satisfiesPzs: $satisfiesPzs, selfLink: $selfLink, storageBillingModel: $storageBillingModel, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all models in the specified dataset. Requires the READER dataset role. After retrieving the list of models, you can get information about a particular model by calling the models.get method.
#
# GET /projects/{projectId}/datasets/{datasetId}/models
# operationId: bigquery.models.list
export def "projects-datasets-models bigquerymodelslist" [
  projectId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --maxResults: int # The maximum number of results to return in a single response page. Leverage the page tokens to iterate through the entire collection.
  --pageToken: string # Page token, returned by a previous call to request the next page of results
]: nothing -> record<models: table<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record, etag: string, expirationTime: string, featureColumns: list, friendlyName: string, hparamSearchSpaces: record, hparamTrials: list, labelColumns: list, labels: record, lastModifiedTime: string, location: string, modelReference: record, modelType: string, optimalTrialIds: list, trainingRuns: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the model specified by modelId from the dataset.
#
# DELETE /projects/{projectId}/datasets/{datasetId}/models/{modelId}
# operationId: bigquery.models.delete
export def "projects-datasets-models bigquerymodelsdelete" [
  projectId: string
  datasetId: string
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/models/($modelId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the specified model resource by model ID.
#
# GET /projects/{projectId}/datasets/{datasetId}/models/{modelId}
# operationId: bigquery.models.get
export def "projects-datasets-models bigquerymodelsget" [
  projectId: string
  datasetId: string
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, featureColumns: table<name: string, type: record>, friendlyName: string, hparamSearchSpaces: record<activationFn: record<candidates: list>, batchSize: record<candidates: record, range: record>, boosterType: record<candidates: list>, colsampleBylevel: record<candidates: record, range: record>, colsampleBynode: record<candidates: record, range: record>, colsampleBytree: record<candidates: record, range: record>, dartNormalizeType: record<candidates: list>, dropout: record<candidates: record, range: record>, hiddenUnits: record<candidates: list>, l1Reg: record<candidates: record, range: record>, l2Reg: record<candidates: record, range: record>, learnRate: record<candidates: record, range: record>, maxTreeDepth: record<candidates: record, range: record>, minSplitLoss: record<candidates: record, range: record>, minTreeChildWeight: record<candidates: record, range: record>, numClusters: record<candidates: record, range: record>, numFactors: record<candidates: record, range: record>, numParallelTree: record<candidates: record, range: record>, optimizer: record<candidates: list>, subsample: record<candidates: record, range: record>, treeMethod: record<candidates: list>, walsAlpha: record<candidates: record, range: record>>, hparamTrials: table<endTimeMs: string, errorMessage: string, evalLoss: float, evaluationMetrics: record, hparamTuningEvaluationMetrics: record, hparams: record, startTimeMs: string, status: string, trainingLoss: float, trialId: string>, labelColumns: table<name: string, type: record>, labels: record, lastModifiedTime: string, location: string, modelReference: record<datasetId: string, modelId: string, projectId: string>, modelType: string, optimalTrialIds: list<string>, trainingRuns: table<classLevelGlobalExplanations: list, dataSplitResult: record, evaluationMetrics: record, modelLevelGlobalExplanation: record, results: list, startTime: string, trainingOptions: record, trainingStartTime: string, vertexAiModelId: string, vertexAiModelVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/models/($modelId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "projects-datasets-models bigquerymodelspatch" [
  projectId: string
  datasetId: string
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --bestTrialId: string # The best trial_id across all training runs. (format: int64)
  --description: string # Optional. A user-friendly description of this model.
  --encryptionConfiguration: record # shape: {kmsKeyName?: string}
  --expirationTime: string # Optional. The time when this model expires, in milliseconds since the epoch. If not present, the model will persist indefinitely. Expired models will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created models. (format: int64)
  --friendlyName: string # Optional. A descriptive name for this model.
  --hparamSearchSpaces: record # Hyperparameter search spaces. These should be a subset of training_options. — shape: {activationFn?: record, batchSize?: record, boosterType?: record, colsampleBylevel?: record, colsampleBynode?: record, colsampleBytree?: record, dartNormalizeType?: record, dropout?: record, hiddenUnits?: record, l1Reg?: record, l2Reg?: record, learnRate?: record, maxTreeDepth?: record, minSplitLoss?: record, minTreeChildWeight?: record, numClusters?: record, numFactors?: record, numParallelTree?: record, optimizer?: record, subsample?: record, treeMethod?: record, walsAlpha?: record}
  --labels: record # The labels associated with this model. You can use these to organize and group your models. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --modelReference: record # shape: {datasetId?: string, modelId?: string, projectId?: string}
  --trainingRuns: list # Information for all training runs in increasing order of start_time. — item shape: {dataSplitResult?: record, evaluationMetrics?: record, modelLevelGlobalExplanation?: record, trainingOptions?: record, vertexAiModelId?: string}
]: any -> record<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, featureColumns: table<name: string, type: record>, friendlyName: string, hparamSearchSpaces: record<activationFn: record<candidates: list>, batchSize: record<candidates: record, range: record>, boosterType: record<candidates: list>, colsampleBylevel: record<candidates: record, range: record>, colsampleBynode: record<candidates: record, range: record>, colsampleBytree: record<candidates: record, range: record>, dartNormalizeType: record<candidates: list>, dropout: record<candidates: record, range: record>, hiddenUnits: record<candidates: list>, l1Reg: record<candidates: record, range: record>, l2Reg: record<candidates: record, range: record>, learnRate: record<candidates: record, range: record>, maxTreeDepth: record<candidates: record, range: record>, minSplitLoss: record<candidates: record, range: record>, minTreeChildWeight: record<candidates: record, range: record>, numClusters: record<candidates: record, range: record>, numFactors: record<candidates: record, range: record>, numParallelTree: record<candidates: record, range: record>, optimizer: record<candidates: list>, subsample: record<candidates: record, range: record>, treeMethod: record<candidates: list>, walsAlpha: record<candidates: record, range: record>>, hparamTrials: table<endTimeMs: string, errorMessage: string, evalLoss: float, evaluationMetrics: record, hparamTuningEvaluationMetrics: record, hparams: record, startTimeMs: string, status: string, trainingLoss: float, trialId: string>, labelColumns: table<name: string, type: record>, labels: record, lastModifiedTime: string, location: string, modelReference: record<datasetId: string, modelId: string, projectId: string>, modelType: string, optimalTrialIds: list<string>, trainingRuns: table<classLevelGlobalExplanations: list, dataSplitResult: record, evaluationMetrics: record, modelLevelGlobalExplanation: record, results: list, startTime: string, trainingOptions: record, trainingStartTime: string, vertexAiModelId: string, vertexAiModelVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/models/($modelId)" $qp)
  let body = {bestTrialId: $bestTrialId, description: $description, encryptionConfiguration: $encryptionConfiguration, expirationTime: $expirationTime, friendlyName: $friendlyName, hparamSearchSpaces: $hparamSearchSpaces, labels: $labels, modelReference: $modelReference, trainingRuns: $trainingRuns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all routines in the specified dataset. Requires the READER dataset role.
#
# GET /projects/{projectId}/datasets/{datasetId}/routines
# operationId: bigquery.routines.list
export def "projects-datasets-routines bigqueryroutineslist" [
  projectId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --filter: string # If set, then only the Routines matching this filter are returned. The current supported form is either "routine_type:" or "routineType:", where is a RoutineType enum. Example: "routineType:SCALAR_FUNCTION".
  --maxResults: int # The maximum number of results to return in a single response page. Leverage the page tokens to iterate through the entire collection.
  --pageToken: string # Page token, returned by a previous call, to request the next page of results
  --readMask: string # If set, then only the Routine fields in the field mask, as well as project_id, dataset_id and routine_id, are returned in the response. If unset, then the following Routine fields are returned: etag, project_id, dataset_id, routine_id, routine_type, creation_time, last_modified_time, and language.
]: nothing -> record<nextPageToken: string, routines: table<arguments: list, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list, language: string, lastModifiedTime: string, remoteFunctionOptions: record, returnTableType: record, returnType: record, routineReference: record, routineType: string, sparkOptions: record, strictMode: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/routines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
# --sparkOptions shape: {archiveUris?: list, connection?: string, containerImage?: string, fileUris?: list, jarUris?: list, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list, runtimeVersion?: string}
export def "projects-datasets-routines bigqueryroutinesinsert" [
  projectId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --arguments: list # Optional. — item shape: {argumentKind?: "ARGUMENT_KIND_UNSPECIFIED"|"FIXED_TYPE"|"ANY_TYPE", dataType?: record, mode?: "MODE_UNSPECIFIED"|"IN"|"OUT"|"INOUT", name?: string}
  --definitionBody: string # Required. The body of the routine. For functions, this is the expression in the AS clause. If language=SQL, it is the substring inside (but excluding) the parentheses. For example, for the function created with the following statement: `CREATE FUNCTION JoinLines(x string, y string) as (concat(x, "\n", y))` The definition_body is `concat(x, "\n", y)` (\n is not replaced with linebreak). If language=JAVASCRIPT, it is the evaluated string in the AS clause. For example, for the function created with the following statement: `CREATE FUNCTION f() RETURNS STRING LANGUAGE js AS 'return "\n";\n'` The definition_body is `return "\n";\n` Note that both \n are replaced with linebreaks.
  --description: string # Optional. The description of the routine, if defined.
  --determinismLevel: string@determinismLevel-completer # Optional. The determinism level of the JavaScript UDF, if defined.
  --importedLibraries: list # Optional. If language = "JAVASCRIPT", this field stores the path of the imported JAVASCRIPT libraries.
  --language: string@language-completer # Optional. Defaults to "SQL" if remote_function_options field is absent, not set otherwise.
  --remoteFunctionOptions: record # Options for a remote user-defined function. — shape: {connection?: string, endpoint?: string, maxBatchingRows?: string, userDefinedContext?: record}
  --returnTableType: record # A table type — shape: {columns?: list}
  --returnType: record # The data type of a variable such as a function argument. Examples include: * INT64: `{"typeKind": "INT64"}` * ARRAY: { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "STRING"} } * STRUCT>: { "typeKind": "STRUCT", "structType": { "fields": [ { "name": "x", "type": {"typeKind": "STRING"} }, { "name": "y", "type": { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "DATE"} } } ] } } — shape: {arrayElementType?: record, structType?: record, typeKind?: "TYPE_KIND_UNSPECIFIED"|"INT64"|"BOOL"|"FLOAT64"|"STRING"|"BYTES"|"TIMESTAMP"|"DATE"|"TIME"|"DATETIME"|"INTERVAL"|"GEOGRAPHY"|"NUMERIC"|"BIGNUMERIC"|"JSON"|"ARRAY"|"STRUCT"}
  --routineReference: record # shape: {datasetId?: string, projectId?: string, routineId?: string}
  --routineType: string@routineType-completer # Required. The type of routine.
  --sparkOptions: record # Options for a user-defined Spark routine. — shape: {archiveUris?: list, connection?: string, containerImage?: string, fileUris?: list, jarUris?: list, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list, runtimeVersion?: string}
  --strictMode: oneof<nothing, bool> # Optional. Can be set for procedures only. If true (default), the definition body will be validated in the creation and the updates of the procedure. For procedures with an argument of ANY TYPE, the definition body validtion is not supported at creation/update time, and thus this field must be set to false explicitly.
]: any -> record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/routines" $qp)
  let body = {arguments: $arguments, definitionBody: $definitionBody, description: $description, determinismLevel: $determinismLevel, importedLibraries: $importedLibraries, language: $language, remoteFunctionOptions: $remoteFunctionOptions, returnTableType: $returnTableType, returnType: $returnType, routineReference: $routineReference, routineType: $routineType, sparkOptions: $sparkOptions, strictMode: $strictMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the routine specified by routineId from the dataset.
#
# DELETE /projects/{projectId}/datasets/{datasetId}/routines/{routineId}
# operationId: bigquery.routines.delete
export def "projects-datasets-routines bigqueryroutinesdelete" [
  projectId: string
  datasetId: string
  routineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/routines/($routineId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the specified routine resource by routine ID.
#
# GET /projects/{projectId}/datasets/{datasetId}/routines/{routineId}
# operationId: bigquery.routines.get
export def "projects-datasets-routines bigqueryroutinesget" [
  projectId: string
  datasetId: string
  routineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --readMask: string # If set, only the Routine fields in the field mask are returned in the response. If unset, all Routine fields are returned.
]: nothing -> record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/routines/($routineId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
# --sparkOptions shape: {archiveUris?: list, connection?: string, containerImage?: string, fileUris?: list, jarUris?: list, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list, runtimeVersion?: string}
export def "projects-datasets-routines bigqueryroutinesupdate" [
  projectId: string
  datasetId: string
  routineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --arguments: list # Optional. — item shape: {argumentKind?: "ARGUMENT_KIND_UNSPECIFIED"|"FIXED_TYPE"|"ANY_TYPE", dataType?: record, mode?: "MODE_UNSPECIFIED"|"IN"|"OUT"|"INOUT", name?: string}
  --definitionBody: string # Required. The body of the routine. For functions, this is the expression in the AS clause. If language=SQL, it is the substring inside (but excluding) the parentheses. For example, for the function created with the following statement: `CREATE FUNCTION JoinLines(x string, y string) as (concat(x, "\n", y))` The definition_body is `concat(x, "\n", y)` (\n is not replaced with linebreak). If language=JAVASCRIPT, it is the evaluated string in the AS clause. For example, for the function created with the following statement: `CREATE FUNCTION f() RETURNS STRING LANGUAGE js AS 'return "\n";\n'` The definition_body is `return "\n";\n` Note that both \n are replaced with linebreaks.
  --description: string # Optional. The description of the routine, if defined.
  --determinismLevel: string@determinismLevel-completer # Optional. The determinism level of the JavaScript UDF, if defined.
  --importedLibraries: list # Optional. If language = "JAVASCRIPT", this field stores the path of the imported JAVASCRIPT libraries.
  --language: string@language-completer # Optional. Defaults to "SQL" if remote_function_options field is absent, not set otherwise.
  --remoteFunctionOptions: record # Options for a remote user-defined function. — shape: {connection?: string, endpoint?: string, maxBatchingRows?: string, userDefinedContext?: record}
  --returnTableType: record # A table type — shape: {columns?: list}
  --returnType: record # The data type of a variable such as a function argument. Examples include: * INT64: `{"typeKind": "INT64"}` * ARRAY: { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "STRING"} } * STRUCT>: { "typeKind": "STRUCT", "structType": { "fields": [ { "name": "x", "type": {"typeKind": "STRING"} }, { "name": "y", "type": { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "DATE"} } } ] } } — shape: {arrayElementType?: record, structType?: record, typeKind?: "TYPE_KIND_UNSPECIFIED"|"INT64"|"BOOL"|"FLOAT64"|"STRING"|"BYTES"|"TIMESTAMP"|"DATE"|"TIME"|"DATETIME"|"INTERVAL"|"GEOGRAPHY"|"NUMERIC"|"BIGNUMERIC"|"JSON"|"ARRAY"|"STRUCT"}
  --routineReference: record # shape: {datasetId?: string, projectId?: string, routineId?: string}
  --routineType: string@routineType-completer # Required. The type of routine.
  --sparkOptions: record # Options for a user-defined Spark routine. — shape: {archiveUris?: list, connection?: string, containerImage?: string, fileUris?: list, jarUris?: list, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list, runtimeVersion?: string}
  --strictMode: oneof<nothing, bool> # Optional. Can be set for procedures only. If true (default), the definition body will be validated in the creation and the updates of the procedure. For procedures with an argument of ANY TYPE, the definition body validtion is not supported at creation/update time, and thus this field must be set to false explicitly.
]: any -> record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/routines/($routineId)" $qp)
  let body = {arguments: $arguments, definitionBody: $definitionBody, description: $description, determinismLevel: $determinismLevel, importedLibraries: $importedLibraries, language: $language, remoteFunctionOptions: $remoteFunctionOptions, returnTableType: $returnTableType, returnType: $returnType, routineReference: $routineReference, routineType: $routineType, sparkOptions: $sparkOptions, strictMode: $strictMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all tables in the specified dataset. Requires the READER dataset role.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables
# operationId: bigquery.tables.list
export def "projects-datasets-tables bigquerytableslist" [
  projectId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --maxResults: int # Maximum number of results to return
  --pageToken: string # Page token, returned by a previous call, to request the next page of results
]: nothing -> record<etag: string, kind: string, nextPageToken: string, tables: table<clustering: record, creationTime: string, expirationTime: string, friendlyName: string, id: string, kind: string, labels: record, rangePartitioning: record, tableReference: record, timePartitioning: record, type: string, view: record>, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/tables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new, empty table in the dataset.
#
# POST /projects/{projectId}/datasets/{datasetId}/tables
# operationId: bigquery.tables.insert
# --cloneDefinition shape: {baseTableReference?: record, cloneTime?: string}
# --clustering shape: {fields?: list}
# --encryptionConfiguration shape: {kmsKeyName?: string}
# --externalDataConfiguration shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list}
# --materializedView shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
# --model shape: {modelOptions?: record, trainingRuns?: list}
# --rangePartitioning shape: {field?: string, range?: record}
# --schema shape: {fields?: list}
# --snapshotDefinition shape: {baseTableReference?: record, snapshotTime?: string}
# --streamingBuffer shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
# --tableReference shape: {datasetId?: string, projectId?: string, tableId?: string}
# --timePartitioning shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
# --view shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
export def "projects-datasets-tables bigquerytablesinsert" [
  projectId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --cloneDefinition: record # shape: {baseTableReference?: record, cloneTime?: string}
  --clustering: record # shape: {fields?: list}
  --creationTime: string # [Output-only] The time when this table was created, in milliseconds since the epoch. (format: int64)
  --defaultCollation: string # [Output-only] The default collation of the table.
  --defaultRoundingMode: string # [Output-only] The default rounding mode of the table.
  --description: string # [Optional] A user-friendly description of this table.
  --encryptionConfiguration: record # shape: {kmsKeyName?: string}
  --etag: string # [Output-only] A hash of the table metadata. Used to ensure there were no concurrent modifications to the resource when attempting an update. Not guaranteed to change when the table contents or the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  --expirationTime: string # [Optional] The time when this table expires, in milliseconds since the epoch. If not present, the table will persist indefinitely. Expired tables will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created tables. (format: int64)
  --externalDataConfiguration: record # shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list}
  --friendlyName: string # [Optional] A descriptive name for this table.
  --id: string # [Output-only] An opaque ID uniquely identifying the table.
  --kind: string # [Output-only] The type of the resource. (default: bigquery#table)
  --labels: record # The labels associated with this table. You can use these to organize and group your tables. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --lastModifiedTime: string # [Output-only] The time when this table was last modified, in milliseconds since the epoch. (format: uint64)
  --location: string # [Output-only] The geographic location where the table resides. This value is inherited from the dataset.
  --materializedView: record # shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
  --maxStaleness: string # [Optional] Max staleness of data that could be returned when table or materialized view is queried (formatted as Google SQL Interval type). (format: byte)
  --model: record # shape: {modelOptions?: record, trainingRuns?: list}
  --numBytes: string # [Output-only] The size of this table in bytes, excluding any data in the streaming buffer. (format: int64)
  --numLongTermBytes: string # [Output-only] The number of bytes in the table that are considered "long-term storage". (format: int64)
  --numPhysicalBytes: string # [Output-only] [TrustedTester] The physical size of this table in bytes, excluding any data in the streaming buffer. This includes compression and storage used for time travel. (format: int64)
  --numRows: string # [Output-only] The number of rows of data in this table, excluding any data in the streaming buffer. (format: uint64)
  --num-active-logical-bytes: string # [Output-only] Number of logical bytes that are less than 90 days old. (format: int64)
  --num-active-physical-bytes: string # [Output-only] Number of physical bytes less than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-long-term-logical-bytes: string # [Output-only] Number of logical bytes that are more than 90 days old. (format: int64)
  --num-long-term-physical-bytes: string # [Output-only] Number of physical bytes more than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-partitions: string # [Output-only] The number of partitions present in the table or materialized view. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-time-travel-physical-bytes: string # [Output-only] Number of physical bytes used by time travel storage (deleted or changed data). This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-total-logical-bytes: string # [Output-only] Total number of logical bytes in the table or materialized view. (format: int64)
  --num-total-physical-bytes: string # [Output-only] The physical size of this table in bytes. This also includes storage used for time travel. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --rangePartitioning: record # shape: {field?: string, range?: record}
  --requirePartitionFilter: oneof<nothing, bool> # [Optional] If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. (default: false)
  --schema: record # shape: {fields?: list}
  --selfLink: string # [Output-only] A URL that can be used to access this resource again.
  --snapshotDefinition: record # shape: {baseTableReference?: record, snapshotTime?: string}
  --streamingBuffer: record # shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
  --tableReference: record # shape: {datasetId?: string, projectId?: string, tableId?: string}
  --timePartitioning: record # shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
  --type: string # [Output-only] Describes the table type. The following values are supported: TABLE: A normal BigQuery table. VIEW: A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only table that is a copy of another table. [TrustedTester] MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table that references data stored in an external storage system, such as Google Cloud Storage. The default value is TABLE.
  --view: record # shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
]: any -> record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/tables" $qp)
  let body = {cloneDefinition: $cloneDefinition, clustering: $clustering, creationTime: $creationTime, defaultCollation: $defaultCollation, defaultRoundingMode: $defaultRoundingMode, description: $description, encryptionConfiguration: $encryptionConfiguration, etag: $etag, expirationTime: $expirationTime, externalDataConfiguration: $externalDataConfiguration, friendlyName: $friendlyName, id: $id, kind: $kind, labels: $labels, lastModifiedTime: $lastModifiedTime, location: $location, materializedView: $materializedView, maxStaleness: $maxStaleness, model: $model, numBytes: $numBytes, numLongTermBytes: $numLongTermBytes, numPhysicalBytes: $numPhysicalBytes, numRows: $numRows, num_active_logical_bytes: $num_active_logical_bytes, num_active_physical_bytes: $num_active_physical_bytes, num_long_term_logical_bytes: $num_long_term_logical_bytes, num_long_term_physical_bytes: $num_long_term_physical_bytes, num_partitions: $num_partitions, num_time_travel_physical_bytes: $num_time_travel_physical_bytes, num_total_logical_bytes: $num_total_logical_bytes, num_total_physical_bytes: $num_total_physical_bytes, rangePartitioning: $rangePartitioning, requirePartitionFilter: $requirePartitionFilter, schema: $schema, selfLink: $selfLink, snapshotDefinition: $snapshotDefinition, streamingBuffer: $streamingBuffer, tableReference: $tableReference, timePartitioning: $timePartitioning, type: $type, view: $view} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the table specified by tableId from the dataset. If the table contains data, all the data will be deleted.
#
# DELETE /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# operationId: bigquery.tables.delete
export def "projects-datasets-tables bigquerytablesdelete" [
  projectId: string
  datasetId: string
  tableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/tables/($tableId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the specified table resource by table ID. This method does not return the data in the table, it only returns the table resource, which describes the structure of this table.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# operationId: bigquery.tables.get
export def "projects-datasets-tables bigquerytablesget" [
  projectId: string
  datasetId: string
  tableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --selectedFields: string # List of fields to return (comma-separated). If unspecified, all fields are returned
  --view: string@view-completer # Specifies the view that determines which table information is returned. By default, basic table information and storage statistics (STORAGE_STATS) are returned.
]: nothing -> record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "selectedFields" $selectedFields "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/tables/($tableId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates information in an existing table. The update method replaces the entire table resource, whereas the patch method only replaces fields that are provided in the submitted table resource. This method supports patch semantics.
#
# PATCH /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# operationId: bigquery.tables.patch
# --cloneDefinition shape: {baseTableReference?: record, cloneTime?: string}
# --clustering shape: {fields?: list}
# --encryptionConfiguration shape: {kmsKeyName?: string}
# --externalDataConfiguration shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list}
# --materializedView shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
# --model shape: {modelOptions?: record, trainingRuns?: list}
# --rangePartitioning shape: {field?: string, range?: record}
# --schema shape: {fields?: list}
# --snapshotDefinition shape: {baseTableReference?: record, snapshotTime?: string}
# --streamingBuffer shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
# --tableReference shape: {datasetId?: string, projectId?: string, tableId?: string}
# --timePartitioning shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
# --view shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
export def "projects-datasets-tables bigquerytablespatch" [
  projectId: string
  datasetId: string
  tableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --autodetect-schema: oneof<nothing, bool> # When true will autodetect schema, else will keep original schema
  --cloneDefinition: record # shape: {baseTableReference?: record, cloneTime?: string}
  --clustering: record # shape: {fields?: list}
  --creationTime: string # [Output-only] The time when this table was created, in milliseconds since the epoch. (format: int64)
  --defaultCollation: string # [Output-only] The default collation of the table.
  --defaultRoundingMode: string # [Output-only] The default rounding mode of the table.
  --description: string # [Optional] A user-friendly description of this table.
  --encryptionConfiguration: record # shape: {kmsKeyName?: string}
  --etag: string # [Output-only] A hash of the table metadata. Used to ensure there were no concurrent modifications to the resource when attempting an update. Not guaranteed to change when the table contents or the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  --expirationTime: string # [Optional] The time when this table expires, in milliseconds since the epoch. If not present, the table will persist indefinitely. Expired tables will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created tables. (format: int64)
  --externalDataConfiguration: record # shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list}
  --friendlyName: string # [Optional] A descriptive name for this table.
  --id: string # [Output-only] An opaque ID uniquely identifying the table.
  --kind: string # [Output-only] The type of the resource. (default: bigquery#table)
  --labels: record # The labels associated with this table. You can use these to organize and group your tables. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --lastModifiedTime: string # [Output-only] The time when this table was last modified, in milliseconds since the epoch. (format: uint64)
  --location: string # [Output-only] The geographic location where the table resides. This value is inherited from the dataset.
  --materializedView: record # shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
  --maxStaleness: string # [Optional] Max staleness of data that could be returned when table or materialized view is queried (formatted as Google SQL Interval type). (format: byte)
  --model: record # shape: {modelOptions?: record, trainingRuns?: list}
  --numBytes: string # [Output-only] The size of this table in bytes, excluding any data in the streaming buffer. (format: int64)
  --numLongTermBytes: string # [Output-only] The number of bytes in the table that are considered "long-term storage". (format: int64)
  --numPhysicalBytes: string # [Output-only] [TrustedTester] The physical size of this table in bytes, excluding any data in the streaming buffer. This includes compression and storage used for time travel. (format: int64)
  --numRows: string # [Output-only] The number of rows of data in this table, excluding any data in the streaming buffer. (format: uint64)
  --num-active-logical-bytes: string # [Output-only] Number of logical bytes that are less than 90 days old. (format: int64)
  --num-active-physical-bytes: string # [Output-only] Number of physical bytes less than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-long-term-logical-bytes: string # [Output-only] Number of logical bytes that are more than 90 days old. (format: int64)
  --num-long-term-physical-bytes: string # [Output-only] Number of physical bytes more than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-partitions: string # [Output-only] The number of partitions present in the table or materialized view. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-time-travel-physical-bytes: string # [Output-only] Number of physical bytes used by time travel storage (deleted or changed data). This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-total-logical-bytes: string # [Output-only] Total number of logical bytes in the table or materialized view. (format: int64)
  --num-total-physical-bytes: string # [Output-only] The physical size of this table in bytes. This also includes storage used for time travel. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --rangePartitioning: record # shape: {field?: string, range?: record}
  --requirePartitionFilter: oneof<nothing, bool> # [Optional] If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. (default: false)
  --schema: record # shape: {fields?: list}
  --selfLink: string # [Output-only] A URL that can be used to access this resource again.
  --snapshotDefinition: record # shape: {baseTableReference?: record, snapshotTime?: string}
  --streamingBuffer: record # shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
  --tableReference: record # shape: {datasetId?: string, projectId?: string, tableId?: string}
  --timePartitioning: record # shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
  --type: string # [Output-only] Describes the table type. The following values are supported: TABLE: A normal BigQuery table. VIEW: A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only table that is a copy of another table. [TrustedTester] MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table that references data stored in an external storage system, such as Google Cloud Storage. The default value is TABLE.
  --view: record # shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
]: any -> record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "autodetect_schema" $autodetect_schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/tables/($tableId)" $qp)
  let body = {cloneDefinition: $cloneDefinition, clustering: $clustering, creationTime: $creationTime, defaultCollation: $defaultCollation, defaultRoundingMode: $defaultRoundingMode, description: $description, encryptionConfiguration: $encryptionConfiguration, etag: $etag, expirationTime: $expirationTime, externalDataConfiguration: $externalDataConfiguration, friendlyName: $friendlyName, id: $id, kind: $kind, labels: $labels, lastModifiedTime: $lastModifiedTime, location: $location, materializedView: $materializedView, maxStaleness: $maxStaleness, model: $model, numBytes: $numBytes, numLongTermBytes: $numLongTermBytes, numPhysicalBytes: $numPhysicalBytes, numRows: $numRows, num_active_logical_bytes: $num_active_logical_bytes, num_active_physical_bytes: $num_active_physical_bytes, num_long_term_logical_bytes: $num_long_term_logical_bytes, num_long_term_physical_bytes: $num_long_term_physical_bytes, num_partitions: $num_partitions, num_time_travel_physical_bytes: $num_time_travel_physical_bytes, num_total_logical_bytes: $num_total_logical_bytes, num_total_physical_bytes: $num_total_physical_bytes, rangePartitioning: $rangePartitioning, requirePartitionFilter: $requirePartitionFilter, schema: $schema, selfLink: $selfLink, snapshotDefinition: $snapshotDefinition, streamingBuffer: $streamingBuffer, tableReference: $tableReference, timePartitioning: $timePartitioning, type: $type, view: $view} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates information in an existing table. The update method replaces the entire table resource, whereas the patch method only replaces fields that are provided in the submitted table resource.
#
# PUT /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# operationId: bigquery.tables.update
# --cloneDefinition shape: {baseTableReference?: record, cloneTime?: string}
# --clustering shape: {fields?: list}
# --encryptionConfiguration shape: {kmsKeyName?: string}
# --externalDataConfiguration shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list}
# --materializedView shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
# --model shape: {modelOptions?: record, trainingRuns?: list}
# --rangePartitioning shape: {field?: string, range?: record}
# --schema shape: {fields?: list}
# --snapshotDefinition shape: {baseTableReference?: record, snapshotTime?: string}
# --streamingBuffer shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
# --tableReference shape: {datasetId?: string, projectId?: string, tableId?: string}
# --timePartitioning shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
# --view shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
export def "projects-datasets-tables bigquerytablesupdate" [
  projectId: string
  datasetId: string
  tableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --autodetect-schema: oneof<nothing, bool> # When true will autodetect schema, else will keep original schema
  --cloneDefinition: record # shape: {baseTableReference?: record, cloneTime?: string}
  --clustering: record # shape: {fields?: list}
  --creationTime: string # [Output-only] The time when this table was created, in milliseconds since the epoch. (format: int64)
  --defaultCollation: string # [Output-only] The default collation of the table.
  --defaultRoundingMode: string # [Output-only] The default rounding mode of the table.
  --description: string # [Optional] A user-friendly description of this table.
  --encryptionConfiguration: record # shape: {kmsKeyName?: string}
  --etag: string # [Output-only] A hash of the table metadata. Used to ensure there were no concurrent modifications to the resource when attempting an update. Not guaranteed to change when the table contents or the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  --expirationTime: string # [Optional] The time when this table expires, in milliseconds since the epoch. If not present, the table will persist indefinitely. Expired tables will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created tables. (format: int64)
  --externalDataConfiguration: record # shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list}
  --friendlyName: string # [Optional] A descriptive name for this table.
  --id: string # [Output-only] An opaque ID uniquely identifying the table.
  --kind: string # [Output-only] The type of the resource. (default: bigquery#table)
  --labels: record # The labels associated with this table. You can use these to organize and group your tables. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --lastModifiedTime: string # [Output-only] The time when this table was last modified, in milliseconds since the epoch. (format: uint64)
  --location: string # [Output-only] The geographic location where the table resides. This value is inherited from the dataset.
  --materializedView: record # shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
  --maxStaleness: string # [Optional] Max staleness of data that could be returned when table or materialized view is queried (formatted as Google SQL Interval type). (format: byte)
  --model: record # shape: {modelOptions?: record, trainingRuns?: list}
  --numBytes: string # [Output-only] The size of this table in bytes, excluding any data in the streaming buffer. (format: int64)
  --numLongTermBytes: string # [Output-only] The number of bytes in the table that are considered "long-term storage". (format: int64)
  --numPhysicalBytes: string # [Output-only] [TrustedTester] The physical size of this table in bytes, excluding any data in the streaming buffer. This includes compression and storage used for time travel. (format: int64)
  --numRows: string # [Output-only] The number of rows of data in this table, excluding any data in the streaming buffer. (format: uint64)
  --num-active-logical-bytes: string # [Output-only] Number of logical bytes that are less than 90 days old. (format: int64)
  --num-active-physical-bytes: string # [Output-only] Number of physical bytes less than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-long-term-logical-bytes: string # [Output-only] Number of logical bytes that are more than 90 days old. (format: int64)
  --num-long-term-physical-bytes: string # [Output-only] Number of physical bytes more than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-partitions: string # [Output-only] The number of partitions present in the table or materialized view. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-time-travel-physical-bytes: string # [Output-only] Number of physical bytes used by time travel storage (deleted or changed data). This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-total-logical-bytes: string # [Output-only] Total number of logical bytes in the table or materialized view. (format: int64)
  --num-total-physical-bytes: string # [Output-only] The physical size of this table in bytes. This also includes storage used for time travel. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --rangePartitioning: record # shape: {field?: string, range?: record}
  --requirePartitionFilter: oneof<nothing, bool> # [Optional] If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. (default: false)
  --schema: record # shape: {fields?: list}
  --selfLink: string # [Output-only] A URL that can be used to access this resource again.
  --snapshotDefinition: record # shape: {baseTableReference?: record, snapshotTime?: string}
  --streamingBuffer: record # shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
  --tableReference: record # shape: {datasetId?: string, projectId?: string, tableId?: string}
  --timePartitioning: record # shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
  --type: string # [Output-only] Describes the table type. The following values are supported: TABLE: A normal BigQuery table. VIEW: A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only table that is a copy of another table. [TrustedTester] MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table that references data stored in an external storage system, such as Google Cloud Storage. The default value is TABLE.
  --view: record # shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
]: any -> record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "autodetect_schema" $autodetect_schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/tables/($tableId)" $qp)
  let body = {cloneDefinition: $cloneDefinition, clustering: $clustering, creationTime: $creationTime, defaultCollation: $defaultCollation, defaultRoundingMode: $defaultRoundingMode, description: $description, encryptionConfiguration: $encryptionConfiguration, etag: $etag, expirationTime: $expirationTime, externalDataConfiguration: $externalDataConfiguration, friendlyName: $friendlyName, id: $id, kind: $kind, labels: $labels, lastModifiedTime: $lastModifiedTime, location: $location, materializedView: $materializedView, maxStaleness: $maxStaleness, model: $model, numBytes: $numBytes, numLongTermBytes: $numLongTermBytes, numPhysicalBytes: $numPhysicalBytes, numRows: $numRows, num_active_logical_bytes: $num_active_logical_bytes, num_active_physical_bytes: $num_active_physical_bytes, num_long_term_logical_bytes: $num_long_term_logical_bytes, num_long_term_physical_bytes: $num_long_term_physical_bytes, num_partitions: $num_partitions, num_time_travel_physical_bytes: $num_time_travel_physical_bytes, num_total_logical_bytes: $num_total_logical_bytes, num_total_physical_bytes: $num_total_physical_bytes, rangePartitioning: $rangePartitioning, requirePartitionFilter: $requirePartitionFilter, schema: $schema, selfLink: $selfLink, snapshotDefinition: $snapshotDefinition, streamingBuffer: $streamingBuffer, tableReference: $tableReference, timePartitioning: $timePartitioning, type: $type, view: $view} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves table data from a specified set of rows. Requires the READER dataset role.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables/{tableId}/data
# operationId: bigquery.tabledata.list
export def "projects-datasets-tables-data bigquerytabledatalist" [
  projectId: string
  datasetId: string
  tableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --maxResults: int # Maximum number of results to return
  --pageToken: string # Page token, returned by a previous call, identifying the result set
  --selectedFields: string # List of fields to return (comma-separated). If unspecified, all fields are returned
  --startIndex: string # Zero-based index of the starting row to read
]: nothing -> record<etag: string, kind: string, pageToken: string, rows: table<f: list>, totalRows: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "selectedFields" $selectedFields "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/tables/($tableId)/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Streams data into BigQuery one record at a time without needing to run a load job. Requires the WRITER dataset role.
#
# POST /projects/{projectId}/datasets/{datasetId}/tables/{tableId}/insertAll
# operationId: bigquery.tabledata.insertAll
# --rows item shape: {insertId?: string, json?: record}
export def "projects-datasets-tables-insert-all bigquerytabledatainsertAll" [
  projectId: string
  datasetId: string
  tableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --ignoreUnknownValues: oneof<nothing, bool> # [Optional] Accept rows that contain values that do not match the schema. The unknown values are ignored. Default is false, which treats unknown values as errors.
  --kind: string # The resource type of the response. (default: bigquery#tableDataInsertAllRequest)
  --rows: list # The rows to insert. — item shape: {insertId?: string, json?: record}
  --skipInvalidRows: oneof<nothing, bool> # [Optional] Insert all valid rows of a request, even if invalid rows exist. The default value is false, which causes the entire request to fail if any invalid rows exist.
  --templateSuffix: string # If specified, treats the destination table as a base template, and inserts the rows into an instance table named "{destination}{templateSuffix}". BigQuery will manage creation of the instance table, using the schema of the base template table. See https://cloud.google.com/bigquery/streaming-data-into-bigquery#template-tables for considerations when working with templates tables.
]: any -> record<insertErrors: table<errors: list, index: int>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/tables/($tableId)/insertAll" $qp)
  let body = {ignoreUnknownValues: $ignoreUnknownValues, kind: $kind, rows: $rows, skipInvalidRows: $skipInvalidRows, templateSuffix: $templateSuffix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all row access policies on the specified table.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables/{tableId}/rowAccessPolicies
# operationId: bigquery.rowAccessPolicies.list
export def "projects-datasets-tables-row-access-policies bigqueryrowAccessPolicieslist" [
  projectId: string
  datasetId: string
  tableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --pageSize: int # The maximum number of results to return in a single response page. Leverage the page tokens to iterate through the entire collection.
  --pageToken: string # Page token, returned by a previous call, to request the next page of results.
]: nothing -> record<nextPageToken: string, rowAccessPolicies: table<creationTime: string, etag: string, filterPredicate: string, lastModifiedTime: string, rowAccessPolicyReference: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/datasets/($datasetId)/tables/($tableId)/rowAccessPolicies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all jobs that you started in the specified project. Job information is available for a six month period after creation. The job list is sorted in reverse chronological order, by job creation time. Requires the Can View project role, or the Is Owner project role if you set the allUsers property.
#
# GET /projects/{projectId}/jobs
# operationId: bigquery.jobs.list
export def "projects-jobs bigqueryjobslist" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --allUsers: oneof<nothing, bool> # Whether to display jobs owned by all users in the project. Default false
  --maxCreationTime: string # Max value for job creation time, in milliseconds since the POSIX epoch. If set, only jobs created before or at this timestamp are returned
  --maxResults: int # Maximum number of results to return
  --minCreationTime: string # Min value for job creation time, in milliseconds since the POSIX epoch. If set, only jobs created after or at this timestamp are returned
  --pageToken: string # Page token, returned by a previous call, to request the next page of results
  --parentJobId: string # If set, retrieves only jobs whose parent is this job. Otherwise, retrieves only jobs which have no parent
  --projection: string@projection-completer # Restrict information returned to a set of selected fields
  --stateFilter: list # Filter for job state
]: nothing -> record<etag: string, jobs: table<configuration: record, errorResult: record, id: string, jobReference: record, kind: string, state: string, statistics: record, status: record, user_email: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "allUsers" $allUsers "scalar") (serialize-qp "maxCreationTime" $maxCreationTime "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "minCreationTime" $minCreationTime "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "parentJobId" $parentJobId "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "stateFilter" $stateFilter "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts a new asynchronous job. Requires the Can View project role.
#
# POST /projects/{projectId}/jobs
# operationId: bigquery.jobs.insert
export def "projects-jobs bigqueryjobsinsert" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --body: record
]: any -> record<configuration: record<copy: record<createDisposition: string, destinationEncryptionConfiguration: record, destinationExpirationTime: any, destinationTable: record, operationType: string, sourceTable: record, sourceTables: list, writeDisposition: string>, dryRun: bool, extract: record<compression: string, destinationFormat: string, destinationUri: string, destinationUris: list, fieldDelimiter: string, printHeader: bool, sourceModel: record, sourceTable: record, useAvroLogicalTypes: bool>, jobTimeoutMs: string, jobType: string, labels: record, load: record<allowJaggedRows: bool, allowQuotedNewlines: bool, autodetect: bool, clustering: record, connectionProperties: list, createDisposition: string, createSession: bool, decimalTargetTypes: list, destinationEncryptionConfiguration: record, destinationTable: record, destinationTableProperties: record, encoding: string, fieldDelimiter: string, hivePartitioningOptions: record, ignoreUnknownValues: bool, jsonExtension: string, maxBadRecords: int, nullMarker: string, parquetOptions: record, preserveAsciiControlCharacters: bool, projectionFields: list, quote: string, rangePartitioning: record, referenceFileSchemaUri: string, schema: record, schemaInline: string, schemaInlineFormat: string, schemaUpdateOptions: list, skipLeadingRows: int, sourceFormat: string, sourceUris: list, timePartitioning: record, useAvroLogicalTypes: bool, writeDisposition: string>, query: record<allowLargeResults: bool, clustering: record, connectionProperties: list, continuous: bool, createDisposition: string, createSession: bool, defaultDataset: record, destinationEncryptionConfiguration: record, destinationTable: record, flattenResults: bool, maximumBillingTier: int, maximumBytesBilled: string, parameterMode: string, preserveNulls: bool, priority: string, query: string, queryParameters: list, rangePartitioning: record, schemaUpdateOptions: list, tableDefinitions: record, timePartitioning: record, useLegacySql: bool, useQueryCache: bool, userDefinedFunctionResources: list, writeDisposition: string>>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record<copied_logical_bytes: string, copied_rows: string>, creationTime: string, dataMaskingStatistics: record<dataMaskingApplied: bool>, endTime: string, extract: record<destinationUriFileCounts: list, inputBytes: string>, load: record<badRecords: string, inputFileBytes: string, inputFiles: string, outputBytes: string, outputRows: string>, numChildJobs: string, parentJobId: string, query: record<biEngineStatistics: record, billingTier: int, cacheHit: bool, ddlAffectedRowAccessPolicyCount: string, ddlDestinationTable: record, ddlOperationPerformed: string, ddlTargetDataset: record, ddlTargetRoutine: record, ddlTargetRowAccessPolicy: record, ddlTargetTable: record, dmlStats: record, estimatedBytesProcessed: string, mlStatistics: record, modelTraining: record, modelTrainingCurrentIteration: int, modelTrainingExpectedTotalIteration: string, numDmlAffectedRows: string, queryPlan: list, referencedRoutines: list, referencedTables: list, reservationUsage: list, schema: record, searchStatistics: record, sparkStatistics: record, statementType: string, timeline: list, totalBytesBilled: string, totalBytesProcessed: string, totalBytesProcessedAccuracy: string, totalPartitionsProcessed: string, totalSlotMs: string, transferredBytes: string, undeclaredQueryParameters: list>, quotaDeferments: list<string>, reservationUsage: list<record>, reservation_id: string, rowLevelSecurityStatistics: record<rowLevelSecurityApplied: bool>, scriptStatistics: record<evaluationKind: string, stackFrames: list>, sessionInfo: record<sessionId: string>, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record<transactionId: string>>, status: record<errorResult: record<debugInfo: string, location: string, message: string, reason: string>, errors: list<record>, state: string>, user_email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Returns information about a specific job. Job information is available for a six month period after creation. Requires that you're the person who ran the job, or have the Is Owner project role.
#
# GET /projects/{projectId}/jobs/{jobId}
# operationId: bigquery.jobs.get
export def "projects-jobs bigqueryjobsget" [
  projectId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location of the job. Required except for US and EU. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
]: nothing -> record<configuration: record<copy: record<createDisposition: string, destinationEncryptionConfiguration: record, destinationExpirationTime: any, destinationTable: record, operationType: string, sourceTable: record, sourceTables: list, writeDisposition: string>, dryRun: bool, extract: record<compression: string, destinationFormat: string, destinationUri: string, destinationUris: list, fieldDelimiter: string, printHeader: bool, sourceModel: record, sourceTable: record, useAvroLogicalTypes: bool>, jobTimeoutMs: string, jobType: string, labels: record, load: record<allowJaggedRows: bool, allowQuotedNewlines: bool, autodetect: bool, clustering: record, connectionProperties: list, createDisposition: string, createSession: bool, decimalTargetTypes: list, destinationEncryptionConfiguration: record, destinationTable: record, destinationTableProperties: record, encoding: string, fieldDelimiter: string, hivePartitioningOptions: record, ignoreUnknownValues: bool, jsonExtension: string, maxBadRecords: int, nullMarker: string, parquetOptions: record, preserveAsciiControlCharacters: bool, projectionFields: list, quote: string, rangePartitioning: record, referenceFileSchemaUri: string, schema: record, schemaInline: string, schemaInlineFormat: string, schemaUpdateOptions: list, skipLeadingRows: int, sourceFormat: string, sourceUris: list, timePartitioning: record, useAvroLogicalTypes: bool, writeDisposition: string>, query: record<allowLargeResults: bool, clustering: record, connectionProperties: list, continuous: bool, createDisposition: string, createSession: bool, defaultDataset: record, destinationEncryptionConfiguration: record, destinationTable: record, flattenResults: bool, maximumBillingTier: int, maximumBytesBilled: string, parameterMode: string, preserveNulls: bool, priority: string, query: string, queryParameters: list, rangePartitioning: record, schemaUpdateOptions: list, tableDefinitions: record, timePartitioning: record, useLegacySql: bool, useQueryCache: bool, userDefinedFunctionResources: list, writeDisposition: string>>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record<copied_logical_bytes: string, copied_rows: string>, creationTime: string, dataMaskingStatistics: record<dataMaskingApplied: bool>, endTime: string, extract: record<destinationUriFileCounts: list, inputBytes: string>, load: record<badRecords: string, inputFileBytes: string, inputFiles: string, outputBytes: string, outputRows: string>, numChildJobs: string, parentJobId: string, query: record<biEngineStatistics: record, billingTier: int, cacheHit: bool, ddlAffectedRowAccessPolicyCount: string, ddlDestinationTable: record, ddlOperationPerformed: string, ddlTargetDataset: record, ddlTargetRoutine: record, ddlTargetRowAccessPolicy: record, ddlTargetTable: record, dmlStats: record, estimatedBytesProcessed: string, mlStatistics: record, modelTraining: record, modelTrainingCurrentIteration: int, modelTrainingExpectedTotalIteration: string, numDmlAffectedRows: string, queryPlan: list, referencedRoutines: list, referencedTables: list, reservationUsage: list, schema: record, searchStatistics: record, sparkStatistics: record, statementType: string, timeline: list, totalBytesBilled: string, totalBytesProcessed: string, totalBytesProcessedAccuracy: string, totalPartitionsProcessed: string, totalSlotMs: string, transferredBytes: string, undeclaredQueryParameters: list>, quotaDeferments: list<string>, reservationUsage: list<record>, reservation_id: string, rowLevelSecurityStatistics: record<rowLevelSecurityApplied: bool>, scriptStatistics: record<evaluationKind: string, stackFrames: list>, sessionInfo: record<sessionId: string>, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record<transactionId: string>>, status: record<errorResult: record<debugInfo: string, location: string, message: string, reason: string>, errors: list<record>, state: string>, user_email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/jobs/($jobId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Requests that a job be cancelled. This call will return immediately, and the client will need to poll for the job status to see if the cancel completed successfully. Cancelled jobs may still incur costs.
#
# POST /projects/{projectId}/jobs/{jobId}/cancel
# operationId: bigquery.jobs.cancel
export def "projects-jobs-cancel bigqueryjobscancel" [
  projectId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location of the job. Required except for US and EU. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
]: nothing -> record<job: record<configuration: record<copy: record, dryRun: bool, extract: record, jobTimeoutMs: string, jobType: string, labels: record, load: record, query: record>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record, creationTime: string, dataMaskingStatistics: record, endTime: string, extract: record, load: record, numChildJobs: string, parentJobId: string, query: record, quotaDeferments: list, reservationUsage: list, reservation_id: string, rowLevelSecurityStatistics: record, scriptStatistics: record, sessionInfo: record, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record>, status: record<errorResult: record, errors: list, state: string>, user_email: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/jobs/($jobId)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Requests the deletion of the metadata of a job. This call returns when the job's metadata is deleted.
#
# DELETE /projects/{projectId}/jobs/{jobId}/delete
# operationId: bigquery.jobs.delete
export def "projects-jobs-delete bigqueryjobsdelete" [
  projectId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location of the job. Required. See details at: https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/jobs/($jobId)/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Runs a BigQuery SQL query synchronously and returns query results if the query completes within a specified timeout.
#
# POST /projects/{projectId}/queries
# operationId: bigquery.jobs.query
# --connectionProperties item shape: {key?: string, value?: string}
# --defaultDataset shape: {datasetId?: string, projectId?: string}
# --queryParameters item shape: {name?: string, parameterType?: record, parameterValue?: record}
export def "projects-queries bigqueryjobsquery" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --connectionProperties: list # Connection properties. — item shape: {key?: string, value?: string}
  --continuous: oneof<nothing, bool> # [Optional] Specifies whether the query should be executed as a continuous query. The default value is false.
  --createSession: oneof<nothing, bool> # If true, creates a new session, where session id will be a server generated random id. If false, runs query with an existing session_id passed in ConnectionProperty, otherwise runs query in non-session mode.
  --defaultDataset: record # shape: {datasetId?: string, projectId?: string}
  --dryRun: oneof<nothing, bool> # [Optional] If set to true, BigQuery doesn't run the job. Instead, if the query is valid, BigQuery returns statistics about the job such as how many bytes would be processed. If the query is invalid, an error returns. The default value is false.
  --kind: string # The resource type of the request. (default: bigquery#queryRequest)
  --labels: record # The labels associated with this job. You can use these to organize and group your jobs. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --location: string # The geographic location where the job should run. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  --maxResults: int # [Optional] The maximum number of rows of data to return per page of results. Setting this flag to a small value such as 1000 and then paging through results might improve reliability when the query result set is large. In addition to this limit, responses are also limited to 10 MB. By default, there is no maximum row count, and only the byte limit applies. (format: uint32)
  --maximumBytesBilled: string # [Optional] Limits the bytes billed for this job. Queries that will have bytes billed beyond this limit will fail (without incurring a charge). If unspecified, this will be set to your project default. (format: int64)
  --parameterMode: string # Standard SQL only. Set to POSITIONAL to use positional (?) query parameters or to NAMED to use named (@myparam) query parameters in this query.
  --preserveNulls: oneof<nothing, bool> # [Deprecated] This property is deprecated.
  --body-query: string # [Required] A query string, following the BigQuery query syntax, of the query to execute. Example: "SELECT count(f1) FROM [myProjectId:myDatasetId.myTableId]".
  --queryParameters: list # Query parameters for Standard SQL queries. — item shape: {name?: string, parameterType?: record, parameterValue?: record}
  --requestId: string # A unique user provided identifier to ensure idempotent behavior for queries. Note that this is different from the job_id. It has the following properties: 1. It is case-sensitive, limited to up to 36 ASCII characters. A UUID is recommended. 2. Read only queries can ignore this token since they are nullipotent by definition. 3. For the purposes of idempotency ensured by the request_id, a request is considered duplicate of another only if they have the same request_id and are actually duplicates. When determining whether a request is a duplicate of the previous request, all parameters in the request that may affect the behavior are considered. For example, query, connection_properties, query_parameters, use_legacy_sql are parameters that affect the result and are considered when determining whether a request is a duplicate, but properties like timeout_ms don't affect the result and are thus not considered. Dry run query requests are never considered duplicate of another request. 4. When a duplicate mutating query request is detected, it returns: a. the results of the mutation if it completes successfully within the timeout. b. the running operation if it is still in progress at the end of the timeout. 5. Its lifetime is limited to 15 minutes. In other words, if two requests are sent with the same request_id, but more than 15 minutes apart, idempotency is not guaranteed.
  --timeoutMs: int # [Optional] How long to wait for the query to complete, in milliseconds, before the request times out and returns. Note that this is only a timeout for the request, not the query. If the query takes longer to run than the timeout value, the call returns without any results and with the 'jobComplete' flag set to false. You can call GetQueryResults() to wait for the query to complete and read the results. The default value is 10000 milliseconds (10 seconds). (format: uint32)
  --useLegacySql: oneof<nothing, bool> # Specifies whether to use BigQuery's legacy SQL dialect for this query. The default value is true. If set to false, the query will use BigQuery's standard SQL: https://cloud.google.com/bigquery/sql-reference/ When useLegacySql is set to false, the value of flattenResults is ignored; query will be run as if flattenResults is false. (default: true)
  --useQueryCache: oneof<nothing, bool> # [Optional] Whether to look for the result in the query cache. The query cache is a best-effort cache that will be flushed whenever tables in the query are modified. The default value is true. (default: true)
]: any -> record<cacheHit: bool, dmlStats: record<deletedRowCount: string, insertedRowCount: string, updatedRowCount: string>, errors: table<debugInfo: string, location: string, message: string, reason: string>, jobComplete: bool, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, numDmlAffectedRows: string, pageToken: string, rows: table<f: list>, schema: record<fields: list<record>>, sessionInfo: record<sessionId: string>, totalBytesProcessed: string, totalRows: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/queries" $qp)
  let body = {connectionProperties: $connectionProperties, continuous: $continuous, createSession: $createSession, defaultDataset: $defaultDataset, dryRun: $dryRun, kind: $kind, labels: $labels, location: $location, maxResults: $maxResults, maximumBytesBilled: $maximumBytesBilled, parameterMode: $parameterMode, preserveNulls: $preserveNulls, query: $body_query, queryParameters: $queryParameters, requestId: $requestId, timeoutMs: $timeoutMs, useLegacySql: $useLegacySql, useQueryCache: $useQueryCache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the results of a query job.
#
# GET /projects/{projectId}/queries/{jobId}
# operationId: bigquery.jobs.getQueryResults
export def "projects-queries bigqueryjobsgetQueryResults" [
  projectId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location where the job should run. Required except for US and EU. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  --maxResults: int # Maximum number of results to read
  --pageToken: string # Page token, returned by a previous call, to request the next page of results
  --startIndex: string # Zero-based index of the starting row
  --timeoutMs: int # How long to wait for the query to complete, in milliseconds, before returning. Default is 10 seconds. If the timeout passes before the job completes, the 'jobComplete' field in the response will be false
]: nothing -> record<cacheHit: bool, errors: table<debugInfo: string, location: string, message: string, reason: string>, etag: string, jobComplete: bool, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, numDmlAffectedRows: string, pageToken: string, rows: table<f: list>, schema: record<fields: list<record>>, totalBytesProcessed: string, totalRows: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "timeoutMs" $timeoutMs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/queries/($jobId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the email address of the service account for your project used for interactions with Google Cloud KMS.
#
# GET /projects/{projectId}/serviceAccount
# operationId: bigquery.projects.getServiceAccount
export def "projects-service-account bigqueryprojectsgetServiceAccount" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<email: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/serviceAccount" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# POST /{resource}:getIamPolicy
# operationId: bigquery.tables.getIamPolicy
# --options shape: {requestedPolicyVersion?: int}
export def "tables bigquerytablesgetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --options: record # Encapsulates settings provided to GetIamPolicy. — shape: {requestedPolicyVersion?: int}
]: any -> record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resource):getIamPolicy" $qp)
  let body = {options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sets the access control policy on the specified resource. Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`, and `PERMISSION_DENIED` errors.
#
# POST /{resource}:setIamPolicy
# operationId: bigquery.tables.setIamPolicy
# --policy shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
export def "tables bigquerytablessetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --updateMask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: `paths: "bindings, etag"` (format: google-fieldmask)
]: any -> record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resource):setIamPolicy" $qp)
  let body = {policy: $policy, updateMask: $updateMask} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a `NOT_FOUND` error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /{resource}:testIamPermissions
# operationId: bigquery.tables.testIamPermissions
export def "tables bigquerytablestestIamPermissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alt: string@alt-completer # Data format for the response.
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --permissions: list # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> record<permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resource):testIamPermissions" $qp)
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
