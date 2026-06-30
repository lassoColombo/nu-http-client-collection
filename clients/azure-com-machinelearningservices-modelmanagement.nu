# Auto-generated client for Azure Machine Learning Model Management Service v2019-09-30
# Source: https://api.apis.guru/v2/specs/azure.com/machinelearningservices-modelManagement/2019-09-30/swagger.json
# Auth: --token flag or $env.AZURE_MACHINE_LEARNING_MODEL_MANAGEMENT_SERVICE_TOKEN

const BASE_URL = "https://azure.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AZURE_MACHINE_LEARNING_MODEL_MANAGEMENT_SERVICE_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def orderby-completer [] { ["CreatedAtAsc" "CreatedAtDesc" "UpdatedAtAsc" "UpdatedAtDesc"] }
def order-by-completer [] { ["CreatedAtAsc" "CreatedAtDesc" "UpdatedAtAsc" "UpdatedAtDesc"] }
def compute-type-completer [] { ["ACI" "AKS" "AKSENDPOINT" "AMLCOMPUTE" "IOT" "UNKNOWN"] }
def deployment-type-completer [] { ["Batch" "GRPCRealtimeEndpoint" "HttpRealtimeEndpoint"] }
def key-type-completer [] { ["Primary" "Secondary"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets list" } } | get name | first)
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

# Query the list of Assets in a workspace.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets
# operationId: Assets_ListQuery
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets list" [
  subscription_id: string
  resource_group: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --run-id: string # The run Id associated with the Assets.
  --name: string # The object name.
  --count: int # The number of items to retrieve in a page. (format: int32)
  --skip-token: string # The continuation token to retrieve the next page.
  --tags: string # A set of tags with which to filter the returned models. It is a comma separated string of tags key or tags key=value Example: tagKey1,tagKey2,tagKey3=value3
  --properties: string # A set of properties with which to filter the returned models. It is a comma separated string of properties key and/or properties key=value Example: propKey1,propKey2,propKey3=value3
  --orderby: string@orderby-completer # An option for specifying how to order the list. (default: CreatedAtDesc)
]: nothing -> record<nextLink: string, value: table<artifacts: list, createdTime: string, description: string, id: string, kvTags: record, meta: record, name: string, properties: record, runid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let qp = [(serialize-qp "runId" $run_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "$skipToken" $skip_token "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "orderby" $orderby "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"runId": $run_id, "name": $name, "count": $count, "$skipToken": $skip_token, "tags": $tags, "properties": $properties, "orderby": $orderby} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an Asset.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets
# operationId: Assets_Create
# --artifacts item shape: {id?: string, prefix?: string}
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets create" [
  subscription_id: string
  resource_group: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifacts: list # A list of child artifacts. — item shape: {id?: string, prefix?: string}
  --description: string # The Asset description.
  --id: string # The Asset Id.
  --kv-tags: record # The Asset tag dictionary. Tags are mutable.
  --meta: record # A dictionary containing metadata about the Asset.
  name: string # The name of the Asset.
  --properties: record # The Asset property dictionary. Properties are immutable.
  --runid: string # The RunId associated with this Asset.
]: any -> record<artifacts: table<id: string, prefix: string>, createdTime: string, description: string, id: string, kvTags: record, meta: record, name: string, properties: record, runid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets") $auth.query)
  let req_body = {"artifacts": $artifacts, "description": $description, "id": $id, "kvTags": $kv_tags, "meta": $meta, "name": $name, "properties": $properties, "runid": $runid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Delete an Asset.
#
# DELETE /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets/{id}
# operationId: Assets_Delete
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets delete" [
  subscription_id: string
  resource_group: string
  workspace: string
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
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Get an Asset.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets/{id}
# operationId: Assets_QueryById
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets list-1" [
  subscription_id: string
  resource_group: string
  workspace: string
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
]: nothing -> record<artifacts: table<id: string, prefix: string>, createdTime: string, description: string, id: string, kvTags: record, meta: record, name: string, properties: record, runid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Update an Asset.
#
# PATCH /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets/{id}
# operationId: Assets_Patch
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets update" [
  subscription_id: string
  resource_group: string
  workspace: string
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
  --body: list
]: any -> record<artifacts: table<id: string, prefix: string>, createdTime: string, description: string, id: string, kvTags: record, meta: record, name: string, properties: record, runid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets/{id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json-patch+json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a list of Image Profiles.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/images/{imageId}/profiles
# operationId: Profiles_ListQuery
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-images-profiles list" [
  subscription_id: string
  resource_group: string
  workspace: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The Profile name.
  --description: string # The Profile description.
  --tags: string # A set of tags with which to filter the returned models. It is a comma separated string of tags key or tags key=value Example: tagKey1,tagKey2,tagKey3=value3
  --properties: string # A set of properties with which to filter the returned models. It is a comma separated string of properties key and/or properties key=value Example: propKey1,propKey2,propKey3=value3
  --count: int # The number of items to retrieve in a page. (format: int32)
  --skip-token: string # The continuation token to retrieve the next page.
  --order-by: string@order-by-completer # The option to order the response. (default: CreatedAtDesc)
]: nothing -> record<nextLink: string, value: table<createdTime: string, description: string, error: record, imageId: string, inputData: string, kvTags: record, name: string, profileRunResult: string, profilingErrorLogs: string, properties: record, recommendationLatencyInMs: float, recommendedCpu: float, recommendedMemoryInGB: float, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "$skipToken" $skip_token "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), image_id: (encode-path-segment $image_id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/images/{image_id}/profiles") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "description": $description, "tags": $tags, "properties": $properties, "count": $count, "$skipToken": $skip_token, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Profile.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/images/{imageId}/profiles
# operationId: Profiles_Create
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-images-profiles create" [
  subscription_id: string
  resource_group: string
  workspace: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The profile description.
  --input-data: string # The profile input data.
  --kv-tags: record # The tags dictionary.
  name: string # The profile name.
  --properties: record # The properties dictionary.
]: any -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), image_id: (encode-path-segment $image_id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/images/{image_id}/profiles") $auth.query)
  let req_body = {"description": $description, "inputData": $input_data, "kvTags": $kv_tags, "name": $name, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Get a Profile.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/images/{imageId}/profiles/{id}
# operationId: Profiles_QueryById
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-images-profiles list-1" [
  subscription_id: string
  resource_group: string
  workspace: string
  image_id: string
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
]: nothing -> record<createdTime: string, description: string, error: record<code: string, details: list<record>, message: string, statusCode: int>, imageId: string, inputData: string, kvTags: record, name: string, profileRunResult: string, profilingErrorLogs: string, properties: record, recommendationLatencyInMs: float, recommendedCpu: float, recommendedMemoryInGB: float, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), image_id: (encode-path-segment $image_id), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/images/{image_id}/profiles/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Query the list of Models in a workspace.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models
# operationId: MLModels_ListQuery
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models list" [
  subscription_id: string
  resource_group: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The object name.
  --framework: string # The framework.
  --description: string # The object description.
  --count: int # The number of items to retrieve in a page. (format: int32)
  --skip-token: string # The continuation token to retrieve the next page.
  --tags: string # A set of tags with which to filter the returned models. It is a comma separated string of tags key or tags key=value Example: tagKey1,tagKey2,tagKey3=value3
  --properties: string # A set of properties with which to filter the returned models. It is a comma separated string of properties key and/or properties key=value Example: propKey1,propKey2,propKey3=value3
  --run-id: string # The runId which created the model.
  --order-by: string@order-by-completer # An option to specify how the models are ordered in the response. (default: CreatedAtDesc)
]: nothing -> record<nextLink: string, value: table<createdTime: string, datasets: list, description: string, experimentName: string, framework: string, frameworkVersion: string, id: string, kvTags: record, mimeType: string, modifiedTime: string, name: string, parentModelId: string, properties: record, runId: string, unpack: bool, url: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "framework" $framework "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "$skipToken" $skip_token "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "runId" $run_id "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "framework": $framework, "description": $description, "count": $count, "$skipToken": $skip_token, "tags": $tags, "properties": $properties, "runId": $run_id, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Register a model.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models
# operationId: MLModels_Register
# --datasets item shape: {id?: string, name?: string}
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models create-ml" [
  subscription_id: string
  resource_group: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasets: list # The list of datasets associated with the model. — item shape: {id?: string, name?: string}
  --description: string # The Model description text. (e.g. A mnist model, first version.)
  --experiment-name: string # The name of the experiment where this model was created.
  --framework: string # The Model framework.
  --framework-version: string # The Model framework version.
  --id: string # The Model Id. (e.g. sklearn_mnist:1)
  --kv-tags: record # The Model tag dictionary. Items are mutable.
  mime_type: string # The MIME type of Model content. For more details about MIME type, please open https://www.iana.org/assignments/media-types/media-types.xhtml
  name: string # The Model name. (e.g. sklearn_mnist)
  --parent-model-id: string # The Parent Model Id. (e.g. sklearn_mnist_root:1)
  --properties: record # The Model property dictionary. Properties are immutable.
  --run-id: string # The RunId that created this model.
  --unpack: oneof<nothing, bool> # Indicates whether we need to unpack the Model during docker Image creation.
  url: string # The URL of the Model. Usually a SAS URL.
  --version: int # The Model version assigned by Model Management Service. (format: int64, e.g. 1)
]: any -> record<createdTime: string, datasets: table<id: string, name: string>, description: string, experimentName: string, framework: string, frameworkVersion: string, id: string, kvTags: record, mimeType: string, modifiedTime: string, name: string, parentModelId: string, properties: record, runId: string, unpack: bool, url: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models") $auth.query)
  let req_body = {"datasets": $datasets, "description": $description, "experimentName": $experiment_name, "framework": $framework, "frameworkVersion": $framework_version, "id": $id, "kvTags": $kv_tags, "mimeType": $mime_type, "name": $name, "parentModelId": $parent_model_id, "properties": $properties, "runId": $run_id, "unpack": $unpack, "url": $url, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Delete the specified Model.
#
# DELETE /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}
# operationId: MLModels_Delete
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models delete-ml" [
  subscription_id: string
  resource_group: string
  workspace: string
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
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets a model.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}
# operationId: MLModels_QueryById
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models list-ml" [
  subscription_id: string
  resource_group: string
  workspace: string
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
]: nothing -> record<createdTime: string, datasets: table<id: string, name: string>, description: string, experimentName: string, framework: string, frameworkVersion: string, id: string, kvTags: record, mimeType: string, modifiedTime: string, name: string, parentModelId: string, properties: record, runId: string, unpack: bool, url: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Patch a specific model.
#
# PATCH /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}
# operationId: MLModels_Patch
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models update-ml" [
  subscription_id: string
  resource_group: string
  workspace: string
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
  --body: list
]: any -> record<createdTime: string, datasets: table<id: string, name: string>, description: string, experimentName: string, framework: string, frameworkVersion: string, id: string, kvTags: record, mimeType: string, modifiedTime: string, name: string, parentModelId: string, properties: record, runId: string, unpack: bool, url: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json-patch+json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve the metrics for a Model.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}/metrics
# operationId: MLModels_GetMetrics
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models-metrics get-ml" [
  subscription_id: string
  resource_group: string
  workspace: string
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
  --start-date: string # The start date from which to retrieve metrics, ISO 8601 literal format.
  --end-date: string # The end date from which to retrieve metrics, ISO 8601 literal format.
]: nothing -> record<deploymentSummary: record<successfulDeployments: int, unsuccessfulDeployments: int>, endTime: string, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}/metrics") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the status of an async operation.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/operations/{id}
# operationId: Operations_Get
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-operations get" [
  subscription_id: string
  resource_group: string
  workspace: string
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
]: nothing -> record<createdTime: string, endTime: string, error: record<code: string, details: list<record>, message: string, statusCode: int>, id: string, operationDetails: record<subOperationState: string, subOperationType: string>, operationLog: string, operationType: string, parentRequestId: string, resourceLocation: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/operations/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Query the list of Services in a Workspace.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services
# operationId: Services_ListQuery
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services list" [
  subscription_id: string
  resource_group: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-id: string # The Image Id.
  --image-name: string # The Image name.
  --model-id: string # The Model Id.
  --model-name: string # The Model name.
  --name: string # The object name.
  --count: int # The number of items to retrieve in a page. (format: int32)
  --compute-type: string # The compute environment type.
  --skip-token: string # The continuation token to retrieve the next page.
  --tags: string # A set of tags with which to filter the returned models. It is a comma separated string of tags key or tags key=value Example: tagKey1,tagKey2,tagKey3=value3
  --properties: string # A set of properties with which to filter the returned models. It is a comma separated string of properties key and/or properties key=value Example: propKey1,propKey2,propKey3=value3
  --expand: oneof<nothing, bool> # Set to True to include Model details. (default: false)
  --orderby: string@orderby-completer # The option to order the response. (default: UpdatedAtDesc)
]: nothing -> record<nextLink: string, value: table<computeType: string, createdTime: string, deploymentType: string, description: string, error: record, id: string, kvTags: record, name: string, operationId: string, properties: record, state: string, updatedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let qp = [(serialize-qp "imageId" $image_id "scalar") (serialize-qp "imageName" $image_name "scalar") (serialize-qp "modelId" $model_id "scalar") (serialize-qp "modelName" $model_name "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "computeType" $compute_type "scalar") (serialize-qp "$skipToken" $skip_token "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "orderby" $orderby "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"imageId": $image_id, "imageName": $image_name, "modelId": $model_id, "modelName": $model_name, "name": $name, "count": $count, "computeType": $compute_type, "$skipToken": $skip_token, "tags": $tags, "properties": $properties, "expand": $expand, "orderby": $orderby} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Service.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services
# Discriminator (request): computeType
# operationId: Services_Create
# --environmentImageRequest shape: {assets?: list, driverProgram?: string, environment?: record, modelIds?: list<string>}
# --keys shape: {primaryKey?: string, secondaryKey?: string}
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services create" [
  subscription_id: string
  resource_group: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  compute_type: string@compute-type-completer # The compute environment type for the service. (e.g. AKS)
  --deployment-type: string@deployment-type-completer # The deployment type for the service. (e.g. HttpRealtimeEndpoint)
  --description: string # The description of the service.
  --environment-image-request: record # Request to create a Docker image based on Environment. — shape: {assets?: list, driverProgram?: string, environment?: record, modelIds?: list<string>}
  --image-id: string # The Image Id.
  --keys: record # shape: {primaryKey?: string, secondaryKey?: string}
  --kv-tags: record # The service tag dictionary. Tags are mutable.
  --location: string # The location of the service.
  name: string # The service name.
  --properties: record # The service properties dictionary. Properties are immutable.
]: any -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services") $auth.query)
  let req_body = {"computeType": $compute_type, "deploymentType": $deployment_type, "description": $description, "environmentImageRequest": $environment_image_request, "imageId": $image_id, "keys": $keys, "kvTags": $kv_tags, "location": $location, "name": $name, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete a Service.
#
# DELETE /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}
# operationId: Services_Delete
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services delete" [
  subscription_id: string
  resource_group: string
  workspace: string
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
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Get a Service.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}
# operationId: Services_QueryById
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services list-1" [
  subscription_id: string
  resource_group: string
  workspace: string
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
  --expand: oneof<nothing, bool> # Set to True to include Model details. (default: false)
]: nothing -> record<computeType: string, createdTime: string, deploymentType: string, description: string, error: record<code: string, details: list<record>, message: string, statusCode: int>, id: string, kvTags: record, name: string, operationId: string, properties: record, state: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Patch a Service.
#
# PATCH /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}
# operationId: Services_Patch
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services update" [
  subscription_id: string
  resource_group: string
  workspace: string
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
  --body: list
]: any -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json-patch+json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Lists Service keys.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}/listkeys
# operationId: Services_ListServiceKeys
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services-listkeys list-keys" [
  subscription_id: string
  resource_group: string
  workspace: string
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
]: nothing -> record<primaryKey: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}/listkeys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Regenerate Service Keys.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}/regenerateKeys
# operationId: Services_RegenerateServiceKeys
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services-regenerate-keys create" [
  subscription_id: string
  resource_group: string
  workspace: string
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
  --key-type: int@key-type-completer # Specification for which type of key to generate. (format: int32, e.g. Primary)
  --key-value: string # The value the key is set to.
]: any -> record<primaryKey: string, secondaryKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}/regenerateKeys") $auth.query)
  let req_body = {"keyType": $key_type, "keyValue": $key_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Generate Service Access Token.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}/token
# operationId: Services_GetServiceToken
export def "modelmanagement-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services-token get" [
  subscription_id: string
  resource_group: string
  workspace: string
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
]: nothing -> record<accessToken: string, expiryOn: int, refreshAfter: int, tokenType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroup' must be non-empty" } }
  if ($workspace | is-empty) { error make --unspanned { msg: "path parameter 'workspace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), workspace: (encode-path-segment $workspace), id: (encode-path-segment $id)} | format pattern "/modelmanagement/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}/token") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}
