# Auto-generated client for Restful API copy v1.0.0
# Source: https://raw.githubusercontent.com/milvus-io/web-content/master/API_Reference/milvus-restful/v2.4.x/Restful%20API%20v2.openapi.json
# Auth: --token flag or $env.RESTFUL_API_COPY_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RESTFUL_API_COPY_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "vectordb-entities-delete post" } } | get name | first)
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

# Delete
#
# POST /v2/vectordb/entities/delete
export def "vectordb-entities-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the target database.
  collectionName: string # The name of an existing collection.
  filter: string # A scalar filtering condition to filter matching entities.    The value defaults to an empty string, indicating that no condition applies. Setting both **id** and **filter** results in an error. You can set this parameter to an empty string to skip scalar filtering. To build a scalar filtering condition, refer to [Boolean Expression Rules](https://milvus.io/docs/boolean.md). 
  --partitionName: string # The name of a partition in the current collection.  If specified, the data is to be deleted from the specified partition.
]: any -> record<code: int, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/entities/delete")
  let body = {dbName: $dbName, collectionName: $collectionName, filter: $filter, partitionName: $partitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Insert
#
# POST /v2/vectordb/entities/insert
export def "vectordb-entities-insert post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the target database.
  collectionName: string # The name of an existing collection.
  data: any # The data to insert into the current collection. The data to insert should be a dictionary that matches the schema of the current collection or a list of such dictionaries. 
  --partitionName: string # The name of a partition in the current collection.  If specified, the data is to be inserted into the specified partition.
]: any -> record<code: int, data: record<insertCount: int, insertIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/entities/insert")
  let body = {dbName: $dbName, collectionName: $collectionName, data: $data, partitionName: $partitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query
#
# POST /v2/vectordb/entities/query
export def "vectordb-entities-query post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database.
  collectionName: string # The name of the collection to which this operation applies.
  --filter: string # The filter used to find matches for the search.
  --outputFields: list # An array of fields to return along with the search results.
  --partitionNames: list # The name of the partitions to which this operation applies.
]: any -> record<code: int, data: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/entities/query")
  let body = {dbName: $dbName, collectionName: $collectionName, filter: $filter, outputFields: $outputFields, partitionNames: $partitionNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Has Collection
#
# POST /v2/vectordb/collections/has
export def "vectordb-collections-has post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation times out when any response returns or an error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  dbName: string # The name of the database in which to check the existence of a collection.
  collectionName: string # The name of an existing collection.
]: any -> record<code: int, data: record<has: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/has")
  let body = {dbName: $dbName, collectionName: $collectionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rename Collection
#
# POST /v2/vectordb/collections/rename
export def "vectordb-collections-rename post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation in seconds. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target collection. Setting this to a non-existing collection results in a **MilvusException**.
  --newDbName: string # The name of the database to which the collection belongs after this operation. The value defaults to **default**. Setting this to a database rather than the one the collection belongs to before this operation moves this collection to the specified database. Setting this to a non-existing database results in a **MilvusException**.
  newCollectionName: string # The name of the target collection after this operation. Setting this to the value of **old_collection_name** results in a **MilvusException**.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/rename")
  let body = {dbName: $dbName, collectionName: $collectionName, newDbName: $newDbName, newCollectionName: $newCollectionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Collection Stats
#
# POST /v2/vectordb/collections/get_stats
export def "vectordb-collections-get-stats post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation in seconds. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  dbName: string # The name of the database which the collection belongs to. Setting this to a non-existing database results in an error.
  collectionName: string # The name of the collection to check. Setting this to a non-existing database results in an error.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/get_stats")
  let body = {dbName: $dbName, collectionName: $collectionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert
#
# POST /v2/vectordb/entities/upsert
export def "vectordb-entities-upsert post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database.
  collectionName: string # The name of the collection in which to upsert data.
  data: any # The data to insert into the current collection.  The data to insert should be a dictionary that matches the schema of the current collection or a list of such dictionaries.
  --partitionName: string # The name of a partition in the current collection.  If specified, the data is to be inserted into the specified partition.
]: any -> record<code: int, data: record<upsertCount: int, upsertIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/entities/upsert")
  let body = {dbName: $dbName, collectionName: $collectionName, data: $data, partitionName: $partitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get
#
# POST /v2/vectordb/entities/get
export def "vectordb-entities-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database.
  collectionName: string # The name of the collection to which this operation applies.
  id: any # A specific entity ID or a list of entity IDs.
  --outputFields: list # An array of fields to return along with the search results.
  --partitionNames: list # The name of the partitions to which this operation applies.
]: any -> record<code: int, data: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/entities/get")
  let body = {dbName: $dbName, collectionName: $collectionName, id: $id, outputFields: $outputFields, partitionNames: $partitionNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search
#
# POST /v2/vectordb/entities/search
# --searchParams shape: {radius?: int, range_filter?: int}
export def "vectordb-entities-search post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database.
  collectionName: string # The name of the collection to which this operation applies.
  vector: list # A list of vector embeddings. <include target="milvus">Milvus</include><include target="zilliz">Zilliz Cloud</include> searches for the most similar vector embeddings to the specified ones.
  --annsField: string
  --filter: string # The filter used to find matches for the search.
  --limit: int # The total number of entities to return. You can use this parameter in combination with **offset** in **param** to enable pagination. The sum of this value and **offset** in **param** should be less than 16,384. 
  --offset: int #     The number of records to skip in the search result.      You can use this parameter in combination with limit to enable pagination.     The sum of this value and limit should be less than 16,384. 
  --groupingField: string # https://zilliverse.feishu.cn/docx/S3brdwmUHoG33dxhifpcruAYnsb
  --outputFields: list # An array of fields to return along with the search results.
  searchParams: record # shape: {radius?: int, range_filter?: int}
  --partitionNames: list # The name of the partitions to which this operation applies.
]: any -> record<code: int, data: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/entities/search")
  let body = {dbName: $dbName, collectionName: $collectionName, vector: $vector, annsField: $annsField, filter: $filter, limit: $limit, offset: $offset, groupingField: $groupingField, outputFields: $outputFields, searchParams: $searchParams, partitionNames: $partitionNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Partitions
#
# POST /v2/vectordb/partitions/list
export def "vectordb-partitions-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # e.g. Bearer {{TOKEN}}
  dbName: string # The name of the target database.
  collectionName: string # The name of the target collection to which the partition belongs.
]: any -> record<code: int, data: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/partitions/list")
  let body = {dbName: $dbName, collectionName: $collectionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Partition
#
# POST /v2/vectordb/partitions/create
export def "vectordb-partitions-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target collection. Setting this to a non-existing collection results in a **MilvusException**.
  partitionName: string # The name of the target parition.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/partitions/create")
  let body = {dbName: $dbName, collectionName: $collectionName, partitionName: $partitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Drop Partition
#
# POST /v2/vectordb/partitions/drop
export def "vectordb-partitions-drop post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target collection. Setting this to a non-existing collection results in a **MilvusException**.
  partitionName: string # The name of the target parition.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/partitions/drop")
  let body = {dbName: $dbName, collectionName: $collectionName, partitionName: $partitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create User
#
# POST /v2/vectordb/users/create
export def "vectordb-users-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  userName: string # The name of the target user. The value should start with a letter and can only contain underline, letters and numbers.
  password: string # The corresponding password to the new user to create.  The password must be a string of 8 to 64 characters and must include at least three of the following character types: uppercase letters, lowercase letters, numbers, and special characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/users/create")
  let body = {userName: $userName, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update User Password
#
# POST /v2/vectordb/users/update_password
export def "vectordb-users-update-password post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authorization token. (e.g. Bearer {{TOKEN}})
  userName: string # The name of the target user. The value should start with a letter and can only contain underline, letters and numbers.
  password: string # The corresponding password to the new user to create.  The password must be a string of 8 to 64 characters and must include at least three of the following character types: uppercase letters, lowercase letters, numbers, and special characters.
  newPassword: string # The new password for the specified user.    The password must be a string of 8 to 64 characters and must include at least three of the following character types: uppercase letters, lowercase letters, numbers, and special characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/users/update_password")
  let body = {userName: $userName, password: $password, newPassword: $newPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Drop User
#
# POST /v2/vectordb/users/drop
export def "vectordb-users-drop post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  userName: string # The name of the target user. The value should start with a letter and can only contain underline, letters and numbers.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/users/drop")
  let body = {userName: $userName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describe User
#
# POST /v2/vectordb/users/describe
export def "vectordb-users-describe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  userName: string #   The name of the user to describe.
]: any -> record<code: int, data: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/users/describe")
  let body = {userName: $userName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Users
#
# POST /v2/vectordb/users/list
export def "vectordb-users-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token (e.g. Bearer {{TOKEN}})
]: nothing -> record<code: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/users/list")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Grant Role To User
#
# POST /v2/vectordb/users/grant_role
export def "vectordb-users-grant-role post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/users/grant_role")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Roles
#
# POST /v2/vectordb/roles/list
export def "vectordb-roles-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/roles/list")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describe Role
#
# POST /v2/vectordb/roles/describe
export def "vectordb-roles-describe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  roleName: string # The name of the role.
]: any -> record<code: int, data: table<object_type: string, privilege: string, object_name: string, db_name: string, grantor: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/roles/describe")
  let body = {roleName: $roleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Role
#
# POST /v2/vectordb/roles/create
export def "vectordb-roles-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # Then authentication token. (e.g. Bearer {{TOKEN}})
  roleName: string # The name of the role.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/roles/create")
  let body = {roleName: $roleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Drop Role
#
# POST /v2/vectordb/roles/drop
export def "vectordb-roles-drop post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  roleName: string # The name of the role.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/roles/drop")
  let body = {roleName: $roleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Grant Privilege To Role
#
# POST /v2/vectordb/roles/grant_privilege
export def "vectordb-roles-grant-privilege post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  roleName: string # The name of the role.
  objectType: string #  The type of the object to which the privilege belongs.
  objectName: string #  The name of the object to which the role is granted the specified privilege.
  privilege: string #  The privilege that is granted to the role.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/roles/grant_privilege")
  let body = {roleName: $roleName, objectType: $objectType, objectName: $objectName, privilege: $privilege} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Index
#
# POST /v2/vectordb/indexes/create
# --indexParams item shape: {metricType: string, fieldName: string, indexName: string, indexConfig?: record}
export def "vectordb-indexes-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target collection. Setting this to a non-existing collection results in a **MilvusException**.
  indexParams: list #   The parameters that apply to the index-building process. — item shape: {metricType: string, fieldName: string, indexName: string, indexConfig?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/indexes/create")
  let body = {dbName: $dbName, collectionName: $collectionName, indexParams: $indexParams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Drop Index
#
# POST /v2/vectordb/indexes/drop
export def "vectordb-indexes-drop post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target collection. Setting this to a non-existing collection results in a **MilvusException**.
  indexName: string # The name fo the target index.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/indexes/drop")
  let body = {dbName: $dbName, collectionName: $collectionName, indexName: $indexName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describe Index
#
# POST /v2/vectordb/indexes/describe
export def "vectordb-indexes-describe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs.
  collectionName: string # The name of an the collection to which the index belongs.
  indexName: string # The name of the index to describe.
]: any -> record<code: int, data: table<fieldName: string, indexName: string, indexState: string, indexType: string, indexedRows: int, metricType: string, pendingRows: int, totalRows: int, failReason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/indexes/describe")
  let body = {dbName: $dbName, collectionName: $collectionName, indexName: $indexName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Collection
#
# POST /v2/vectordb/collections/load
export def "vectordb-collections-load post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Header: int # The timeout duration for this operation in seconds. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs.  (e.g. )
  --Authorization: string # The authentication token (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target collection. Setting this to a non-existing collection results in a **MilvusException**.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/load")
  let body = {dbName: $dbName, collectionName: $collectionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Header": $Request_Header, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Release Collection
#
# POST /v2/vectordb/collections/release
export def "vectordb-collections-release post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation times out when any response returns or an error occurs. (e.g. )
  --Authorization: string # The authentication token (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the cpllection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target colletion. Setting this to a non-existing collection results in a **MilvusException**.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/release")
  let body = {dbName: $dbName, collectionName: $collectionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Partitions
#
# POST /v2/vectordb/partitions/load
export def "vectordb-partitions-load post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target collection. Setting this to a non-existing collection results in a **MilvusException**.
  partitionNames: list # The list of names of the target partitions.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/partitions/load")
  let body = {dbName: $dbName, collectionName: $collectionName, partitionNames: $partitionNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Release Partitions
#
# POST /v2/vectordb/partitions/release
export def "vectordb-partitions-release post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target collection. Setting this to a non-existing collection results in a **MilvusException**.
  partitionNames: list # The list of names of the target partitions.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/partitions/release")
  let body = {dbName: $dbName, collectionName: $collectionName, partitionNames: $partitionNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Collection
#
# POST /v2/vectordb/collections/create
# --schema shape: {autoId: string, enableDynamicField: string, fields: list}
# --indexParams item shape: {metricType: string, fieldName: string, indexName: string, indexConfig?: record}
# --params shape: {max_length?: string, enableDynamicField?: string, shardsNum?: string, consistencyLevel?: string, partitionsNum?: string, ttlSeconds?: string}
export def "vectordb-collections-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation times out when any response returns or an error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database. <zilliz>This parameter applies only to dedicated clusters.</zilliz>
  --collectionName: string # The name of the collection to create.
  --dimension: int # The number of dimensions a vector value should have. This is required if **dtype** of this field is set to **DataType.FLOAT_VECTOR**.
  --metricType: string # The metric type applied to this operation.  Possible values are **L2**, **IP**, and **COSINE**.
  --idType: string # The data type of the primary field. This parameter is designed for the quick-setup of a collection and will be ignored if __schema__ is defined.
  autoID: string # Whether the primary field automatically increments. This parameter is designed for the quick-setup of a collection and will be ignored if __schema__ is defined. (default: false)
  --primaryFieldName: string # The name of the primary field. This parameter is designed for the quick-setup of a collection and will be ignored if __schema__ is defined.
  --vectorFieldName: string # The name of the vector field. This parameter is designed for the quick-setup of a collection and will be ignored if __schema__ is defined.
  --schema: record # shape: {autoId: string, enableDynamicField: string, fields: list}
  --indexParams: list # The parameters that apply to the index-building process. — item shape: {metricType: string, fieldName: string, indexName: string, indexConfig?: record}
  --params: record # shape: {max_length?: string, enableDynamicField?: string, shardsNum?: string, consistencyLevel?: string, partitionsNum?: string, ttlSeconds?: string}
]: any -> record<code: int, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/create")
  let body = {dbName: $dbName, collectionName: $collectionName, dimension: $dimension, metricType: $metricType, idType: $idType, autoID: $autoID, primaryFieldName: $primaryFieldName, vectorFieldName: $vectorFieldName, schema: $schema, indexParams: $indexParams, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Has Partition
#
# POST /v2/vectordb/partitions/has
export def "vectordb-partitions-has post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of an existing database. The value defaults to __default__.
  collectionName: string # The name of an existing collection.
  partitionName: string # The name of the partition to test.
]: any -> record<code: int, data: record<has: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/partitions/has")
  let body = {dbName: $dbName, collectionName: $collectionName, partitionName: $partitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Partition Statistics
#
# POST /v2/vectordb/partitions/get_stats
export def "vectordb-partitions-get-stats post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of an existing database. The value defaults to __default__.
  collectionName: string # The name of an existing collection.
  partitionName: string # The name of the target partition of this operation. 
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/partitions/get_stats")
  let body = {dbName: $dbName, collectionName: $collectionName, partitionName: $partitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoker Role From User
#
# POST /v2/vectordb/users/revoke_role
export def "vectordb-users-revoke-role post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # Then authentication token (e.g. Bearer {{TOKEN}})
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/users/revoke_role")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke Privilege From Role
#
# POST /v2/vectordb/roles/revoke_privilege
export def "vectordb-roles-revoke-privilege post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  roleName: string # The name of the role.
  objectType: string # The type of the object to which the privilege belongs.
  objectName: string # The name of the object to which the role is granted the specified privilege.
  privilege: string # The privilege that is granted to the role.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/roles/revoke_privilege")
  let body = {roleName: $roleName, objectType: $objectType, objectName: $objectName, privilege: $privilege} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Collection Load State
#
# POST /v2/vectordb/collections/get_load_state
export def "vectordb-collections-get-load-state post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation times out when any response returns or an error occurs. (e.g. )
  --Authorization: string # e.g. Bearer {{TOKEN}}
  --dbName: string # The name of a database to which the collection belongs.
  collectionName: string # The name of a collection.
  --partitionNames: string # A list of partition names. If any partition names are specified, releasing any of these partitions results in the return of a NotLoad state.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/get_load_state")
  let body = {dbName: $dbName, collectionName: $collectionName, partitionNames: $partitionNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Indexes
#
# POST /v2/vectordb/indexes/list
export def "vectordb-indexes-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  dbName: string # The name of the database to which the collection belongs.
  --collectionName: string # The name of an existing collection. Setting this to a non-existing collection leads to an error.
]: any -> record<code: int, data: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/indexes/list")
  let body = {dbName: $dbName, collectionName: $collectionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Collections
#
# POST /v2/vectordb/collections/list
export def "vectordb-collections-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation times out when any response returns or an error occurs.  (e.g. )
  --Authorization: string # The authentication token (e.g. Bearer {{TOKEN}})
  dbName: string # The name of an existing database.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/list")
  let body = {dbName: $dbName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describe Collection
#
# POST /v2/vectordb/collections/describe
export def "vectordb-collections-describe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation. Setting this to None indicates that this operation times out when any response returns or an error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  dbName: string # The name of the database.
  collectionName: string # The name of the collection to describe.
]: any -> record<code: int, data: record<collectionName: string, autoID: bool, description: string, enableDynamicField: bool, fields: list<record>, indexes: list<record>, load: string, shardsNum: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/describe")
  let body = {dbName: $dbName, collectionName: $collectionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Drop Collection
#
# POST /v2/vectordb/collections/drop
export def "vectordb-collections-drop post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation.  Setting this to **None** indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs. Setting this to a non-existing database results in a **MilvusException**.
  collectionName: string # The name of the target collection. Setting this to a non-existing collection results in a **MilvusException**.
]: any -> record<code: int, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/collections/drop")
  let body = {dbName: $dbName, collectionName: $collectionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Aliases
#
# POST /v2/vectordb/aliases/list
export def "vectordb-aliases-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation in seconds. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  dbName: string # The name of an existing database. The value defaults to __default__.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/aliases/list")
  let body = {dbName: $dbName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describe Alias
#
# POST /v2/vectordb/aliases/describe
export def "vectordb-aliases-describe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation in seconds. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  dbName: string # The name of the database to which the collection belongs.
  aliasName: string # The name of the alias whose details are to be listed.
]: any -> record<code: int, data: record<dbName: string, collectionName: string, aliasName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/aliases/describe")
  let body = {dbName: $dbName, aliasName: $aliasName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Alter Alias
#
# POST /v2/vectordb/aliases/alter
export def "vectordb-aliases-alter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation in seconds. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/aliases/alter")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Drop Alias
#
# POST /v2/vectordb/aliases/drop
export def "vectordb-aliases-drop post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation in seconds. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --dbName: string # The name of the database to which the collection belongs.
  collectionName: string # The name of the collection to which the alias is assigned to.
  aliasName: string # The alias to drop. When dropping an alias, you do not need to provide the collection name because one alias can only be assigned to exactly one collection. Therefore, the server knows which collection the specified alias belongs to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/aliases/drop")
  let body = {dbName: $dbName, collectionName: $collectionName, aliasName: $aliasName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Alias
#
# POST /v2/vectordb/aliases/create
export def "vectordb-aliases-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The timeout duration for this operation in seconds. Setting this to None indicates that this operation timeouts when any response arrives or any error occurs. (e.g. )
  --Authorization: string # The authentication token. (e.g. Bearer {{TOKEN}})
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vectordb/aliases/create")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
