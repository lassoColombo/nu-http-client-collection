# Auto-generated client for AWS IoT SiteWise v2019-12-02
# Source: https://api.apis.guru/v2/specs/amazonaws.com/iotsitewise/2019-12-02/openapi.json
# Auth: --token flag or $env.AWS_IOT_SITEWISE_TOKEN

const BASE_URL = "http://iotsitewise.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_IOT_SITEWISE_TOKEN | default "" }
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

def base-url-completer [] { ["http://iotsitewise.us-east-1.amazonaws.com" "http://iotsitewise.us-east-2.amazonaws.com" "http://iotsitewise.us-west-1.amazonaws.com" "http://iotsitewise.us-west-2.amazonaws.com" "http://iotsitewise.us-gov-west-1.amazonaws.com" "http://iotsitewise.us-gov-east-1.amazonaws.com" "http://iotsitewise.ca-central-1.amazonaws.com" "http://iotsitewise.eu-north-1.amazonaws.com" "http://iotsitewise.eu-west-1.amazonaws.com" "http://iotsitewise.eu-west-2.amazonaws.com" "http://iotsitewise.eu-west-3.amazonaws.com" "http://iotsitewise.eu-central-1.amazonaws.com" "http://iotsitewise.eu-south-1.amazonaws.com" "http://iotsitewise.af-south-1.amazonaws.com" "http://iotsitewise.ap-northeast-1.amazonaws.com" "http://iotsitewise.ap-northeast-2.amazonaws.com" "http://iotsitewise.ap-northeast-3.amazonaws.com" "http://iotsitewise.ap-southeast-1.amazonaws.com" "http://iotsitewise.ap-southeast-2.amazonaws.com" "http://iotsitewise.ap-east-1.amazonaws.com" "http://iotsitewise.ap-south-1.amazonaws.com" "http://iotsitewise.sa-east-1.amazonaws.com" "http://iotsitewise.me-south-1.amazonaws.com" "https://iotsitewise.us-east-1.amazonaws.com" "https://iotsitewise.us-east-2.amazonaws.com" "https://iotsitewise.us-west-1.amazonaws.com" "https://iotsitewise.us-west-2.amazonaws.com" "https://iotsitewise.us-gov-west-1.amazonaws.com" "https://iotsitewise.us-gov-east-1.amazonaws.com" "https://iotsitewise.ca-central-1.amazonaws.com" "https://iotsitewise.eu-north-1.amazonaws.com" "https://iotsitewise.eu-west-1.amazonaws.com" "https://iotsitewise.eu-west-2.amazonaws.com" "https://iotsitewise.eu-west-3.amazonaws.com" "https://iotsitewise.eu-central-1.amazonaws.com" "https://iotsitewise.eu-south-1.amazonaws.com" "https://iotsitewise.af-south-1.amazonaws.com" "https://iotsitewise.ap-northeast-1.amazonaws.com" "https://iotsitewise.ap-northeast-2.amazonaws.com" "https://iotsitewise.ap-northeast-3.amazonaws.com" "https://iotsitewise.ap-southeast-1.amazonaws.com" "https://iotsitewise.ap-southeast-2.amazonaws.com" "https://iotsitewise.ap-east-1.amazonaws.com" "https://iotsitewise.ap-south-1.amazonaws.com" "https://iotsitewise.sa-east-1.amazonaws.com" "https://iotsitewise.me-south-1.amazonaws.com" "http://iotsitewise.cn-north-1.amazonaws.com.cn" "http://iotsitewise.cn-northwest-1.amazonaws.com.cn" "https://iotsitewise.cn-north-1.amazonaws.com.cn" "https://iotsitewise.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def access-policy-permission-completer [] { ["ADMINISTRATOR" "VIEWER"] }
def identity-type-completer [] { ["GROUP" "IAM" "USER"] }
def resource-type-completer [] { ["PORTAL" "PROJECT"] }
def filter-completer [] { ["ALL" "TOP_LEVEL"] }
def filter-completer-1 [] { ["ALL" "CANCELLED" "COMPLETED" "COMPLETED_WITH_FAILURES" "FAILED" "PENDING" "RUNNING"] }
def portal-auth-mode-completer [] { ["IAM" "SSO"] }
def property-notification-state-completer [] { ["DISABLED" "ENABLED"] }
def encryption-type-completer [] { ["KMS_BASED_ENCRYPTION" "SITEWISE_DEFAULT_ENCRYPTION"] }
def storage-type-completer [] { ["MULTI_LAYER_STORAGE" "SITEWISE_DEFAULT_STORAGE"] }
def disassociated-data-storage-completer [] { ["DISABLED" "ENABLED"] }
def time-ordering-completer [] { ["ASCENDING" "DESCENDING"] }
def quality-completer [] { ["BAD" "GOOD" "UNCERTAIN"] }
def filter-completer-2 [] { ["ALL" "BASE"] }
def traversal-type-completer [] { ["PATH_TO_ROOT"] }
def traversal-direction-completer [] { ["CHILD" "PARENT"] }
def time-series-type-completer [] { ["ASSOCIATED" "DISASSOCIATED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "assets-associate create" } } | get name | first)
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

# Associates a child asset with the given parent asset through a hierarchy defined in the parent asset's model. For more information, see Associating assets (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/add-associated-assets.html) in the IoT SiteWise User Guide.
#
# POST /assets/{assetId}/associate
# operationId: AssociateAssets
export def "assets-associate create" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  hierarchy_id: string # The ID of a hierarchy in the parent asset's model. Hierarchies allow different groupings of assets to be formed that all come from the same asset model. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide.
  child_asset_id: string # The ID of the child asset to be associated.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/assets/{asset_id}/associate"))
  let req_body = {"hierarchyId": $hierarchy_id, "childAssetId": $child_asset_id, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Associates a time series (data stream) with an asset property.
#
# POST /timeseries/associate/#alias&assetId&propertyId
# operationId: AssociateTimeSeriesToAssetProperty
export def "timeseries-associate-aliasasset-idproperty-id create-time-series-to-asset-property" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string # The alias that identifies the time series.
  --asset-id: string # The ID of the asset in which the asset property was created.
  --property-id: string # The ID of the asset property.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alias" $alias "scalar") (serialize-qp "assetId" $asset_id "scalar") (serialize-qp "propertyId" $property_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/associate/#alias&assetId&propertyId" $qp)
  let req_body = {"clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Associates a group (batch) of assets with an IoT SiteWise Monitor project.
#
# POST /projects/{projectId}/assets/associate
# operationId: BatchAssociateProjectAssets
export def "projects-assets-associate create-batch" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_ids: list<string> # The IDs of the assets to be associated to the project.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> record<errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/assets/associate"))
  let req_body = {"assetIds": $asset_ids, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disassociates a group (batch) of assets from an IoT SiteWise Monitor project.
#
# POST /projects/{projectId}/assets/disassociate
# operationId: BatchDisassociateProjectAssets
export def "projects-assets-disassociate create-batch" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_ids: list<string> # The IDs of the assets to be disassociated from the project.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> record<errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/assets/disassociate"))
  let req_body = {"assetIds": $asset_ids, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets aggregated values (for example, average, minimum, and maximum) for one or more asset properties. For more information, see Querying aggregates (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#aggregates) in the IoT SiteWise User Guide.
#
# POST /properties/batch/aggregates
# operationId: BatchGetAssetPropertyAggregates
# --entries item shape: {entryId: any, assetId?: any, propertyId?: any, propertyAlias?: any, aggregateTypes: any, resolution: any, startDate: any, endDate: any, qualities?: any, timeOrdering?: any}
export def "properties-batch-aggregates get-asset-property" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  entries: list # The list of asset property aggregate entries for the batch get request. You can specify up to 16 entries per request. — item shape: {entryId: any, assetId?: any, propertyId?: any, propertyAlias?: any, aggregateTypes: any, resolution: any, startDate: any, endDate: any, qualities?: any, timeOrdering?: any}
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. A result set is returned in the two cases, whichever occurs first. The size of the result set is less than 1 MB. The number of data points in the result set is less than the value of maxResults. The maximum value of maxResults is 4000.
]: any -> record<errorEntries: record, successEntries: record, skippedEntries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/properties/batch/aggregates" $qp)
  let req_body = {"entries": $entries, "nextToken": $next_token, "maxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the current value for one or more asset properties. For more information, see Querying current values (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#current-values) in the IoT SiteWise User Guide.
#
# POST /properties/batch/latest
# operationId: BatchGetAssetPropertyValue
# --entries item shape: {entryId: any, assetId?: any, propertyId?: any, propertyAlias?: any}
export def "properties-batch-latest get-asset-property-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  entries: list # The list of asset property value entries for the batch get request. You can specify up to 128 entries per request. — item shape: {entryId: any, assetId?: any, propertyId?: any, propertyAlias?: any}
  --next-token: string # The token to be used for the next set of paginated results.
]: any -> record<errorEntries: record, successEntries: record, skippedEntries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/properties/batch/latest" $qp)
  let req_body = {"entries": $entries, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the historical values for one or more asset properties. For more information, see Querying historical values (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#historical-values) in the IoT SiteWise User Guide.
#
# POST /properties/batch/history
# operationId: BatchGetAssetPropertyValueHistory
# --entries item shape: {entryId: any, assetId?: any, propertyId?: any, propertyAlias?: any, startDate?: any, endDate?: any, qualities?: any, timeOrdering?: any}
export def "properties-batch-history get-asset-property-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  entries: list # The list of asset property historical value entries for the batch get request. You can specify up to 16 entries per request. — item shape: {entryId: any, assetId?: any, propertyId?: any, propertyAlias?: any, startDate?: any, endDate?: any, qualities?: any, timeOrdering?: any}
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. A result set is returned in the two cases, whichever occurs first. The size of the result set is less than 1 MB. The number of data points in the result set is less than the value of maxResults. The maximum value of maxResults is 4000.
]: any -> record<errorEntries: record, successEntries: record, skippedEntries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/properties/batch/history" $qp)
  let req_body = {"entries": $entries, "nextToken": $next_token, "maxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Sends a list of asset property values to IoT SiteWise. Each value is a timestamp-quality-value (TQV) data point. For more information, see Ingesting data using the API (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/ingest-api.html) in the IoT SiteWise User Guide. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html). With respect to Unix epoch time, IoT SiteWise accepts only TQVs that have a timestamp of no more than 7 days in the past and no more than 10 minutes in the future. IoT SiteWise rejects timestamps outside of the inclusive range of [-7 days, +10 minutes] and returns a TimestampOutOfRangeException error. For each asset property, IoT SiteWise overwrites TQVs with duplicate timestamps unless the newer TQV has a different quality. For example, if you store a TQV {T1, GOOD, V1}, then storing {T1, GOOD, V2} replaces the existing TQV. IoT SiteWise authorizes access to each BatchPutAssetPropertyValue entry individually. For more information, see BatchPutAssetPropertyValue authorization (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/security_iam_service-with-iam.html#security_iam_service-with-iam-id-based-policies-batchputassetpropertyvalue-action) in the IoT SiteWise User Guide.
#
# POST /properties
# operationId: BatchPutAssetPropertyValue
# --entries item shape: {entryId: any, assetId?: any, propertyId?: any, propertyAlias?: any, propertyValues: any}
export def "properties update-batch-asset-property-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  entries: list # The list of asset property value entries for the batch put request. You can specify up to 10 entries per request. — item shape: {entryId: any, assetId?: any, propertyId?: any, propertyAlias?: any, propertyValues: any}
]: any -> record<errorEntries: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/properties")
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an access policy that grants the specified identity (IAM Identity Center user, IAM Identity Center group, or IAM user) access to the specified IoT SiteWise Monitor portal or project resource.
#
# POST /access-policies
# operationId: CreateAccessPolicy
# --accessPolicyIdentity shape: {user?: any, group?: any, iamUser?: any, iamRole?: any}
# --accessPolicyResource shape: {portal?: any, project?: any}
export def "access-policies create-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  access_policy_identity: record # Contains an identity that can access an IoT SiteWise Monitor resource. Currently, you can't use Amazon Web Services APIs to retrieve IAM Identity Center identity IDs. You can find the IAM Identity Center identity IDs in the URL of user and group pages in the IAM Identity Center console (https://console.aws.amazon.com/singlesignon). — shape: {user?: any, group?: any, iamUser?: any, iamRole?: any}
  access_policy_resource: record # Contains an IoT SiteWise Monitor resource ID for a portal or project. — shape: {portal?: any, project?: any}
  access_policy_permission: string@access-policy-permission-completer # The permission level for this access policy. Note that a project ADMINISTRATOR is also known as a project owner.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the access policy. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> record<accessPolicyId: record, accessPolicyArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access-policies")
  let req_body = {"accessPolicyIdentity": $access_policy_identity, "accessPolicyResource": $access_policy_resource, "accessPolicyPermission": $access_policy_permission, "clientToken": $client_token, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a paginated list of access policies for an identity (an IAM Identity Center user, an IAM Identity Center group, or an IAM user) or an IoT SiteWise Monitor resource (a portal or project).
#
# GET /access-policies
# operationId: ListAccessPolicies
export def "access-policies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-type: string@identity-type-completer # The type of identity (IAM Identity Center user, IAM Identity Center group, or IAM user). This parameter is required if you specify identityId.
  --identity-id: string # The ID of the identity. This parameter is required if you specify USER or GROUP for identityType.
  --resource-type: string@resource-type-completer # The type of resource (portal or project). This parameter is required if you specify resourceId.
  --resource-id: string # The ID of the resource. This parameter is required if you specify resourceType.
  --iam-arn: string # The ARN of the IAM user. For more information, see IAM ARNs (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html) in the IAM User Guide. This parameter is required if you specify IAM for identityType.
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<accessPolicySummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identityType" $identity_type "scalar") (serialize-qp "identityId" $identity_id "scalar") (serialize-qp "resourceType" $resource_type "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "iamArn" $iam_arn "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/access-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an asset from an existing asset model. For more information, see Creating assets (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/create-assets.html) in the IoT SiteWise User Guide.
#
# POST /assets
# operationId: CreateAsset
export def "assets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_name: string # A friendly name for the asset.
  asset_model_id: string # The ID of the asset model from which to create the asset.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the asset. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
  --asset-description: string # A description for the asset.
]: any -> record<assetId: record, assetArn: record, assetStatus: record<state: record, error: record<code: record, message: record, details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets")
  let req_body = {"assetName": $asset_name, "assetModelId": $asset_model_id, "clientToken": $client_token, "tags": $tags, "assetDescription": $asset_description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a paginated list of asset summaries. You can use this operation to do the following: List assets based on a specific asset model. List top-level assets. You can't use this operation to list all assets. To retrieve summaries for all of your assets, use ListAssetModels (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_ListAssetModels.html) to get all of your asset model IDs. Then, use ListAssets to get all assets for each asset model.
#
# GET /assets
# operationId: ListAssets
export def "assets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --asset-model-id: string # The ID of the asset model by which to filter the list of assets. This parameter is required if you choose ALL for filter.
  --filter: string@filter-completer # The filter for the requested list of assets. Choose one of the following options: ALL – The list includes all assets for a given asset model ID. The assetModelId parameter is required if you filter by ALL. TOP_LEVEL – The list includes only top-level assets in the asset hierarchy tree. Default: ALL
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "assetModelId" $asset_model_id "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an asset model from specified property and hierarchy definitions. You create assets from asset models. With asset models, you can easily create assets of the same type that have standardized definitions. Each asset created from a model inherits the asset model's property and hierarchy definitions. For more information, see Defining asset models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/define-models.html) in the IoT SiteWise User Guide.
#
# POST /asset-models
# operationId: CreateAssetModel
# --assetModelProperties item shape: {name: any, dataType: any, dataTypeSpec?: any, unit?: any, type: any}
# --assetModelHierarchies item shape: {name: any, childAssetModelId: any}
# --assetModelCompositeModels item shape: {name: any, description?: any, type: any, properties?: any}
export def "asset-models create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_model_name: string # A unique, friendly name for the asset model.
  --asset-model-description: string # A description for the asset model.
  --asset-model-properties: list # The property definitions of the asset model. For more information, see Asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-properties.html) in the IoT SiteWise User Guide. You can specify up to 200 properties per asset model. For more information, see Quotas (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/quotas.html) in the IoT SiteWise User Guide. — item shape: {name: any, dataType: any, dataTypeSpec?: any, unit?: any, type: any}
  --asset-model-hierarchies: list # The hierarchy definitions of the asset model. Each hierarchy specifies an asset model whose assets can be children of any other assets created from this asset model. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide. You can specify up to 10 hierarchies per asset model. For more information, see Quotas (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/quotas.html) in the IoT SiteWise User Guide. — item shape: {name: any, childAssetModelId: any}
  --asset-model-composite-models: list # The composite asset models that are part of this asset model. Composite asset models are asset models that contain specific properties. Each composite model has a type that defines the properties that the composite model supports. Use composite asset models to define alarms on this asset model. — item shape: {name: any, description?: any, type: any, properties?: any}
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the asset model. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> record<assetModelId: record, assetModelArn: record, assetModelStatus: record<state: record, error: record<code: record, message: record, details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset-models")
  let req_body = {"assetModelName": $asset_model_name, "assetModelDescription": $asset_model_description, "assetModelProperties": $asset_model_properties, "assetModelHierarchies": $asset_model_hierarchies, "assetModelCompositeModels": $asset_model_composite_models, "clientToken": $client_token, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a paginated list of summaries of all asset models.
#
# GET /asset-models
# operationId: ListAssetModels
export def "asset-models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetModelSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/asset-models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Defines a job to ingest data to IoT SiteWise from Amazon S3. For more information, see Create a bulk import job (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/CreateBulkImportJob.html) in the Amazon Simple Storage Service User Guide. You must enable IoT SiteWise to export data to Amazon S3 before you create a bulk import job. For more information about how to configure storage settings, see PutStorageConfiguration (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_PutStorageConfiguration.html).
#
# POST /jobs
# operationId: CreateBulkImportJob
# --files item shape: {bucket: any, key: any, versionId?: any}
# --errorReportLocation shape: {bucket?: any, prefix?: any}
# --jobConfiguration shape: {fileFormat?: any}
export def "jobs create-bulk-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_name: string # The unique name that helps identify the job request.
  job_role_arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the IAM role that allows IoT SiteWise to read Amazon S3 data.
  files: list # The files in the specified Amazon S3 bucket that contain your data. — item shape: {bucket: any, key: any, versionId?: any}
  error_report_location: record # The Amazon S3 destination where errors associated with the job creation request are saved. — shape: {bucket?: any, prefix?: any}
  job_configuration: record # Contains the configuration information of a job, such as the file format used to save data in Amazon S3. — shape: {fileFormat?: any}
]: any -> record<jobId: record, jobName: record, jobStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jobs")
  let req_body = {"jobName": $job_name, "jobRoleArn": $job_role_arn, "files": $files, "errorReportLocation": $error_report_location, "jobConfiguration": $job_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a paginated list of bulk import job requests. For more information, see List bulk import jobs (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/ListBulkImportJobs.html) in the IoT SiteWise User Guide.
#
# GET /jobs
# operationId: ListBulkImportJobs
export def "jobs list-bulk-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request.
  --filter: string@filter-completer-1 # You can use a filter to select the bulk import jobs that you want to retrieve.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<jobSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a dashboard in an IoT SiteWise Monitor project.
#
# POST /dashboards
# operationId: CreateDashboard
export def "dashboards create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  project_id: string # The ID of the project in which to create the dashboard.
  dashboard_name: string # A friendly name for the dashboard.
  --dashboard-description: string # A description for the dashboard.
  dashboard_definition: string # The dashboard definition specified in a JSON literal. For detailed information, see Creating dashboards (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/create-dashboards-using-aws-cli.html) in the IoT SiteWise User Guide.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the dashboard. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> record<dashboardId: record, dashboardArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards")
  let req_body = {"projectId": $project_id, "dashboardName": $dashboard_name, "dashboardDescription": $dashboard_description, "dashboardDefinition": $dashboard_definition, "clientToken": $client_token, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a gateway, which is a virtual or edge device that delivers industrial data streams from local servers to IoT SiteWise. For more information, see Ingesting data using a gateway (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/gateway-connector.html) in the IoT SiteWise User Guide.
#
# POST /20200301/gateways
# operationId: CreateGateway
# --gatewayPlatform shape: {greengrass?: any, greengrassV2?: any}
export def "20200301-gateways create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  gateway_name: string # A unique, friendly name for the gateway.
  gateway_platform: record # Contains a gateway's platform information. — shape: {greengrass?: any, greengrassV2?: any}
  --tags: record # A list of key-value pairs that contain metadata for the gateway. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> record<gatewayId: record, gatewayArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/20200301/gateways")
  let req_body = {"gatewayName": $gateway_name, "gatewayPlatform": $gateway_platform, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a paginated list of gateways.
#
# GET /20200301/gateways
# operationId: ListGateways
export def "20200301-gateways list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<gatewaySummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/20200301/gateways" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a portal, which can contain projects and dashboards. IoT SiteWise Monitor uses IAM Identity Center or IAM to authenticate portal users and manage user permissions. Before you can sign in to a new portal, you must add at least one identity to that portal. For more information, see Adding or removing portal administrators (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/administer-portals.html#portal-change-admins) in the IoT SiteWise User Guide.
#
# POST /portals
# operationId: CreatePortal
# --portalLogoImageFile shape: {data?: any, type?: any}
# --alarms shape: {alarmRoleArn?: any, notificationLambdaArn?: any}
export def "portals create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  portal_name: string # A friendly name for the portal.
  --portal-description: string # A description for the portal.
  portal_contact_email: string # The Amazon Web Services administrator's contact email address.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --portal-logo-image-file: record # Contains an image file. — shape: {data?: any, type?: any}
  role_arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of a service role that allows the portal's users to access your IoT SiteWise resources on your behalf. For more information, see Using service roles for IoT SiteWise Monitor (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/monitor-service-role.html) in the IoT SiteWise User Guide.
  --tags: record # A list of key-value pairs that contain metadata for the portal. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
  --portal-auth-mode: string@portal-auth-mode-completer # The service to use to authenticate users to the portal. Choose from the following options: SSO – The portal uses IAM Identity Center (successor to Single Sign-On) to authenticate users and manage user permissions. Before you can create a portal that uses IAM Identity Center, you must enable IAM Identity Center. For more information, see Enabling IAM Identity Center (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/monitor-get-started.html#mon-gs-sso) in the IoT SiteWise User Guide. This option is only available in Amazon Web Services Regions other than the China Regions. IAM – The portal uses Identity and Access Management to authenticate users and manage user permissions. You can't change this value after you create a portal. Default: SSO
  --notification-sender-email: string # The email address that sends alarm notifications. If you use the IoT Events managed Lambda function (https://docs.aws.amazon.com/iotevents/latest/developerguide/lambda-support.html) to manage your emails, you must verify the sender email address in Amazon SES (https://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html).
  --alarms: record # Contains the configuration information of an alarm created in an IoT SiteWise Monitor portal. You can use the alarm to monitor an asset property and get notified when the asset property value is outside a specified range. For more information, see Monitoring with alarms (https://docs.aws.amazon.com/iot-sitewise/latest/appguide/monitor-alarms.html) in the IoT SiteWise Application Guide. — shape: {alarmRoleArn?: any, notificationLambdaArn?: any}
]: any -> record<portalId: record, portalArn: record, portalStartUrl: record, portalStatus: record<state: record, error: record<code: record, message: record>>, ssoApplicationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portals")
  let req_body = {"portalName": $portal_name, "portalDescription": $portal_description, "portalContactEmail": $portal_contact_email, "clientToken": $client_token, "portalLogoImageFile": $portal_logo_image_file, "roleArn": $role_arn, "tags": $tags, "portalAuthMode": $portal_auth_mode, "notificationSenderEmail": $notification_sender_email, "alarms": $alarms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a paginated list of IoT SiteWise Monitor portals.
#
# GET /portals
# operationId: ListPortals
export def "portals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<portalSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/portals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a project in the specified portal. Make sure that the project name and description don't contain confidential information.
#
# POST /projects
# operationId: CreateProject
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  portal_id: string # The ID of the portal in which to create the project.
  project_name: string # A friendly name for the project.
  --project-description: string # A description for the project.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the project. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> record<projectId: record, projectArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let req_body = {"portalId": $portal_id, "projectName": $project_name, "projectDescription": $project_description, "clientToken": $client_token, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an access policy that grants the specified identity access to the specified IoT SiteWise Monitor resource. You can use this operation to revoke access to an IoT SiteWise Monitor resource.
#
# DELETE /access-policies/{accessPolicyId}
# operationId: DeleteAccessPolicy
export def "access-policies delete-policy" [
  access_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientToken" $client_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({access_policy_id: (encode-path-segment $access_policy_id)} | format pattern "/access-policies/{access_policy_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes an access policy, which specifies an identity's access to an IoT SiteWise Monitor portal or project.
#
# GET /access-policies/{accessPolicyId}
# operationId: DescribeAccessPolicy
export def "access-policies get-policy" [
  access_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<accessPolicyId: record, accessPolicyArn: record, accessPolicyIdentity: record<user: record<id: record>, group: record<id: record>, iamUser: record<arn: record>, iamRole: record<arn: record>>, accessPolicyResource: record<portal: record<id: record>, project: record<id: record>>, accessPolicyPermission: record, accessPolicyCreationDate: record, accessPolicyLastUpdateDate: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_policy_id: (encode-path-segment $access_policy_id)} | format pattern "/access-policies/{access_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing access policy that specifies an identity's access to an IoT SiteWise Monitor portal or project resource.
#
# PUT /access-policies/{accessPolicyId}
# operationId: UpdateAccessPolicy
# --accessPolicyIdentity shape: {user?: any, group?: any, iamUser?: any, iamRole?: any}
# --accessPolicyResource shape: {portal?: any, project?: any}
export def "access-policies update-policy" [
  access_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  access_policy_identity: record # Contains an identity that can access an IoT SiteWise Monitor resource. Currently, you can't use Amazon Web Services APIs to retrieve IAM Identity Center identity IDs. You can find the IAM Identity Center identity IDs in the URL of user and group pages in the IAM Identity Center console (https://console.aws.amazon.com/singlesignon). — shape: {user?: any, group?: any, iamUser?: any, iamRole?: any}
  access_policy_resource: record # Contains an IoT SiteWise Monitor resource ID for a portal or project. — shape: {portal?: any, project?: any}
  access_policy_permission: string@access-policy-permission-completer # The permission level for this access policy. Note that a project ADMINISTRATOR is also known as a project owner.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_policy_id: (encode-path-segment $access_policy_id)} | format pattern "/access-policies/{access_policy_id}"))
  let req_body = {"accessPolicyIdentity": $access_policy_identity, "accessPolicyResource": $access_policy_resource, "accessPolicyPermission": $access_policy_permission, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an asset. This action can't be undone. For more information, see Deleting assets and models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/delete-assets-and-models.html) in the IoT SiteWise User Guide. You can't delete an asset that's associated to another asset. For more information, see DisassociateAssets (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DisassociateAssets.html).
#
# DELETE /assets/{assetId}
# operationId: DeleteAsset
export def "assets delete" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetStatus: record<state: record, error: record<code: record, message: record, details: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientToken" $client_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/assets/{asset_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about an asset.
#
# GET /assets/{assetId}
# operationId: DescribeAsset
export def "assets get" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-properties: oneof<nothing, bool> # Whether or not to exclude asset properties from the response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetId: record, assetArn: record, assetName: record, assetModelId: record, assetProperties: record, assetHierarchies: record, assetCompositeModels: record, assetCreationDate: record, assetLastUpdateDate: record, assetStatus: record<state: record, error: record<code: record, message: record, details: record>>, assetDescription: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludeProperties" $exclude_properties "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/assets/{asset_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an asset's name. For more information, see Updating assets and models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/update-assets-and-models.html) in the IoT SiteWise User Guide.
#
# PUT /assets/{assetId}
# operationId: UpdateAsset
export def "assets update" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_name: string # A friendly name for the asset.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --asset-description: string # A description for the asset.
]: any -> record<assetStatus: record<state: record, error: record<code: record, message: record, details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/assets/{asset_id}"))
  let req_body = {"assetName": $asset_name, "clientToken": $client_token, "assetDescription": $asset_description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an asset model. This action can't be undone. You must delete all assets created from an asset model before you can delete the model. Also, you can't delete an asset model if a parent asset model exists that contains a property formula expression that depends on the asset model that you want to delete. For more information, see Deleting assets and models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/delete-assets-and-models.html) in the IoT SiteWise User Guide.
#
# DELETE /asset-models/{assetModelId}
# operationId: DeleteAssetModel
export def "asset-models delete" [
  asset_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetModelStatus: record<state: record, error: record<code: record, message: record, details: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientToken" $client_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_model_id: (encode-path-segment $asset_model_id)} | format pattern "/asset-models/{asset_model_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about an asset model.
#
# GET /asset-models/{assetModelId}
# operationId: DescribeAssetModel
export def "asset-models get" [
  asset_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-properties: oneof<nothing, bool> # Whether or not to exclude asset model properties from the response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetModelId: record, assetModelArn: record, assetModelName: record, assetModelDescription: record, assetModelProperties: record, assetModelHierarchies: record, assetModelCompositeModels: record, assetModelCreationDate: record, assetModelLastUpdateDate: record, assetModelStatus: record<state: record, error: record<code: record, message: record, details: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludeProperties" $exclude_properties "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_model_id: (encode-path-segment $asset_model_id)} | format pattern "/asset-models/{asset_model_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an asset model and all of the assets that were created from the model. Each asset created from the model inherits the updated asset model's property and hierarchy definitions. For more information, see Updating assets and models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/update-assets-and-models.html) in the IoT SiteWise User Guide. This operation overwrites the existing model with the provided model. To avoid deleting your asset model's properties or hierarchies, you must include their IDs and definitions in the updated asset model payload. For more information, see DescribeAssetModel (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeAssetModel.html). If you remove a property from an asset model, IoT SiteWise deletes all previous data for that property. If you remove a hierarchy definition from an asset model, IoT SiteWise disassociates every asset associated with that hierarchy. You can't change the type or data type of an existing property.
#
# PUT /asset-models/{assetModelId}
# operationId: UpdateAssetModel
# --assetModelProperties item shape: {id?: any, name: any, dataType: any, dataTypeSpec?: any, unit?: any, type: any}
# --assetModelHierarchies item shape: {id?: any, name: any, childAssetModelId: any}
# --assetModelCompositeModels item shape: {name: any, description?: any, type: any, properties?: any, id?: any}
export def "asset-models update" [
  asset_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_model_name: string # A unique, friendly name for the asset model.
  --asset-model-description: string # A description for the asset model.
  --asset-model-properties: list # The updated property definitions of the asset model. For more information, see Asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-properties.html) in the IoT SiteWise User Guide. You can specify up to 200 properties per asset model. For more information, see Quotas (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/quotas.html) in the IoT SiteWise User Guide. — item shape: {id?: any, name: any, dataType: any, dataTypeSpec?: any, unit?: any, type: any}
  --asset-model-hierarchies: list # The updated hierarchy definitions of the asset model. Each hierarchy specifies an asset model whose assets can be children of any other assets created from this asset model. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide. You can specify up to 10 hierarchies per asset model. For more information, see Quotas (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/quotas.html) in the IoT SiteWise User Guide. — item shape: {id?: any, name: any, childAssetModelId: any}
  --asset-model-composite-models: list # The composite asset models that are part of this asset model. Composite asset models are asset models that contain specific properties. Each composite model has a type that defines the properties that the composite model supports. Use composite asset models to define alarms on this asset model. — item shape: {name: any, description?: any, type: any, properties?: any, id?: any}
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> record<assetModelStatus: record<state: record, error: record<code: record, message: record, details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_model_id: (encode-path-segment $asset_model_id)} | format pattern "/asset-models/{asset_model_id}"))
  let req_body = {"assetModelName": $asset_model_name, "assetModelDescription": $asset_model_description, "assetModelProperties": $asset_model_properties, "assetModelHierarchies": $asset_model_hierarchies, "assetModelCompositeModels": $asset_model_composite_models, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a dashboard from IoT SiteWise Monitor.
#
# DELETE /dashboards/{dashboardId}
# operationId: DeleteDashboard
export def "dashboards delete" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientToken" $client_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/dashboards/{dashboard_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about a dashboard.
#
# GET /dashboards/{dashboardId}
# operationId: DescribeDashboard
export def "dashboards get" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<dashboardId: record, dashboardArn: record, dashboardName: record, projectId: record, dashboardDescription: record, dashboardDefinition: record, dashboardCreationDate: record, dashboardLastUpdateDate: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/dashboards/{dashboard_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an IoT SiteWise Monitor dashboard.
#
# PUT /dashboards/{dashboardId}
# operationId: UpdateDashboard
export def "dashboards update" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  dashboard_name: string # A new friendly name for the dashboard.
  --dashboard-description: string # A new description for the dashboard.
  dashboard_definition: string # The new dashboard definition, as specified in a JSON literal. For detailed information, see Creating dashboards (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/create-dashboards-using-aws-cli.html) in the IoT SiteWise User Guide.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/dashboards/{dashboard_id}"))
  let req_body = {"dashboardName": $dashboard_name, "dashboardDescription": $dashboard_description, "dashboardDefinition": $dashboard_definition, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a gateway from IoT SiteWise. When you delete a gateway, some of the gateway's files remain in your gateway's file system.
#
# DELETE /20200301/gateways/{gatewayId}
# operationId: DeleteGateway
export def "20200301-gateways delete" [
  gateway_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gateway_id: (encode-path-segment $gateway_id)} | format pattern "/20200301/gateways/{gateway_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about a gateway.
#
# GET /20200301/gateways/{gatewayId}
# operationId: DescribeGateway
export def "20200301-gateways get" [
  gateway_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<gatewayId: record, gatewayName: record, gatewayArn: record, gatewayPlatform: record<greengrass: record<groupArn: record>, greengrassV2: record<coreDeviceThingName: record>>, gatewayCapabilitySummaries: record, creationDate: record, lastUpdateDate: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gateway_id: (encode-path-segment $gateway_id)} | format pattern "/20200301/gateways/{gateway_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a gateway's name.
#
# PUT /20200301/gateways/{gatewayId}
# operationId: UpdateGateway
export def "20200301-gateways update" [
  gateway_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  gateway_name: string # A unique, friendly name for the gateway.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gateway_id: (encode-path-segment $gateway_id)} | format pattern "/20200301/gateways/{gateway_id}"))
  let req_body = {"gatewayName": $gateway_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a portal from IoT SiteWise Monitor.
#
# DELETE /portals/{portalId}
# operationId: DeletePortal
export def "portals delete" [
  portal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<portalStatus: record<state: record, error: record<code: record, message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientToken" $client_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({portal_id: (encode-path-segment $portal_id)} | format pattern "/portals/{portal_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about a portal.
#
# GET /portals/{portalId}
# operationId: DescribePortal
export def "portals get" [
  portal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<portalId: record, portalArn: record, portalName: record, portalDescription: record, portalClientId: record, portalStartUrl: record, portalContactEmail: record, portalStatus: record<state: record, error: record<code: record, message: record>>, portalCreationDate: record, portalLastUpdateDate: record, portalLogoImageLocation: record<id: record, url: record>, roleArn: record, portalAuthMode: record, notificationSenderEmail: record, alarms: record<alarmRoleArn: record, notificationLambdaArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({portal_id: (encode-path-segment $portal_id)} | format pattern "/portals/{portal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an IoT SiteWise Monitor portal.
#
# PUT /portals/{portalId}
# operationId: UpdatePortal
# --portalLogoImage shape: {id?: any, file?: record}
# --alarms shape: {alarmRoleArn?: any, notificationLambdaArn?: any}
export def "portals update" [
  portal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  portal_name: string # A new friendly name for the portal.
  --portal-description: string # A new description for the portal.
  portal_contact_email: string # The Amazon Web Services administrator's contact email address.
  --portal-logo-image: record # Contains an image that is one of the following: An image file. Choose this option to upload a new image. The ID of an existing image. Choose this option to keep an existing image. — shape: {id?: any, file?: record}
  role_arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of a service role that allows the portal's users to access your IoT SiteWise resources on your behalf. For more information, see Using service roles for IoT SiteWise Monitor (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/monitor-service-role.html) in the IoT SiteWise User Guide.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --notification-sender-email: string # The email address that sends alarm notifications.
  --alarms: record # Contains the configuration information of an alarm created in an IoT SiteWise Monitor portal. You can use the alarm to monitor an asset property and get notified when the asset property value is outside a specified range. For more information, see Monitoring with alarms (https://docs.aws.amazon.com/iot-sitewise/latest/appguide/monitor-alarms.html) in the IoT SiteWise Application Guide. — shape: {alarmRoleArn?: any, notificationLambdaArn?: any}
]: any -> record<portalStatus: record<state: record, error: record<code: record, message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({portal_id: (encode-path-segment $portal_id)} | format pattern "/portals/{portal_id}"))
  let req_body = {"portalName": $portal_name, "portalDescription": $portal_description, "portalContactEmail": $portal_contact_email, "portalLogoImage": $portal_logo_image, "roleArn": $role_arn, "clientToken": $client_token, "notificationSenderEmail": $notification_sender_email, "alarms": $alarms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a project from IoT SiteWise Monitor.
#
# DELETE /projects/{projectId}
# operationId: DeleteProject
export def "projects delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientToken" $client_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about a project.
#
# GET /projects/{projectId}
# operationId: DescribeProject
export def "projects get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<projectId: record, projectArn: record, projectName: record, portalId: record, projectDescription: record, projectCreationDate: record, projectLastUpdateDate: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an IoT SiteWise Monitor project.
#
# PUT /projects/{projectId}
# operationId: UpdateProject
export def "projects update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  project_name: string # A new friendly name for the project.
  --project-description: string # A new description for the project.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let req_body = {"projectName": $project_name, "projectDescription": $project_description, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a time series (data stream). If you delete a time series that's associated with an asset property, the asset property still exists, but the time series will no longer be associated with this asset property. To identify a time series, do one of the following: If the time series isn't associated with an asset property, specify the alias of the time series. If the time series is associated with an asset property, specify one of the following: The alias of the time series. The assetId and propertyId that identifies the asset property.
#
# POST /timeseries/delete/
# operationId: DeleteTimeSeries
export def "timeseries-delete delete-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string # The alias that identifies the time series.
  --asset-id: string # The ID of the asset in which the asset property was created.
  --property-id: string # The ID of the asset property.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alias" $alias "scalar") (serialize-qp "assetId" $asset_id "scalar") (serialize-qp "propertyId" $property_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/delete/" $qp)
  let req_body = {"clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves information about an asset property. When you call this operation for an attribute property, this response includes the default attribute value that you define in the asset model. If you update the default value in the model, this operation's response includes the new default value. This operation doesn't return the value of the asset property. To get the value of an asset property, use GetAssetPropertyValue (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_GetAssetPropertyValue.html).
#
# GET /assets/{assetId}/properties/{propertyId}
# operationId: DescribeAssetProperty
export def "assets-properties get-property" [
  asset_id: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetId: record, assetName: record, assetModelId: record, assetProperty: record<id: record, name: record, alias: record, notification: record<topic: record, state: record>, dataType: record, unit: record, type: record<attribute: record, measurement: record, transform: record, metric: record>>, compositeModel: record<name: record, type: record, assetProperty: record<id: record, name: record, alias: record, notification: record, dataType: record, unit: record, type: record>, id: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id), property_id: (encode-path-segment $property_id)} | format pattern "/assets/{asset_id}/properties/{property_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an asset property's alias and notification state. This operation overwrites the property's existing alias and notification state. To keep your existing property's alias or notification state, you must include the existing values in the UpdateAssetProperty request. For more information, see DescribeAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeAssetProperty.html).
#
# PUT /assets/{assetId}/properties/{propertyId}
# operationId: UpdateAssetProperty
export def "assets-properties update-property" [
  asset_id: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide. If you omit this parameter, the alias is removed from the property.
  --property-notification-state: string@property-notification-state-completer # The MQTT notification state (enabled or disabled) for this asset property. When the notification state is enabled, IoT SiteWise publishes property value updates to a unique MQTT topic. For more information, see Interacting with other services (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/interact-with-other-services.html) in the IoT SiteWise User Guide. If you omit this parameter, the notification state is set to DISABLED.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --property-unit: string # The unit of measure (such as Newtons or RPM) of the asset property. If you don't specify a value for this parameter, the service uses the value of the assetModelProperty in the asset model.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id), property_id: (encode-path-segment $property_id)} | format pattern "/assets/{asset_id}/properties/{property_id}"))
  let req_body = {"propertyAlias": $property_alias, "propertyNotificationState": $property_notification_state, "clientToken": $client_token, "propertyUnit": $property_unit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves information about a bulk import job request. For more information, see Describe a bulk import job (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/DescribeBulkImportJob.html) in the Amazon Simple Storage Service User Guide.
#
# GET /jobs/{jobId}
# operationId: DescribeBulkImportJob
export def "jobs get-bulk-import" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<jobId: record, jobName: record, jobStatus: record, jobRoleArn: record, files: record, errorReportLocation: record<bucket: record, prefix: record>, jobConfiguration: record<fileFormat: record<csv: record>>, jobCreationDate: record, jobLastUpdateDate: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about the default encryption configuration for the Amazon Web Services account in the default or specified Region. For more information, see Key management (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/key-management.html) in the IoT SiteWise User Guide.
#
# GET /configuration/account/encryption
# operationId: DescribeDefaultEncryptionConfiguration
export def "configuration-account-encryption get-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<encryptionType: record, kmsKeyArn: record, configurationStatus: record<state: record, error: record<code: record, message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration/account/encryption")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the default encryption configuration for the Amazon Web Services account. For more information, see Key management (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/key-management.html) in the IoT SiteWise User Guide.
#
# POST /configuration/account/encryption
# operationId: PutDefaultEncryptionConfiguration
export def "configuration-account-encryption update-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  encryption_type: string@encryption-type-completer # The type of encryption used for the encryption configuration.
  --kms-key-id: string # The Key ID of the customer managed key used for KMS encryption. This is required if you use KMS_BASED_ENCRYPTION.
]: any -> record<encryptionType: record, kmsKeyArn: record, configurationStatus: record<state: record, error: record<code: record, message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration/account/encryption")
  let req_body = {"encryptionType": $encryption_type, "kmsKeyId": $kms_key_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves information about a gateway capability configuration. Each gateway capability defines data sources for a gateway. A capability configuration can contain multiple data source configurations. If you define OPC-UA sources for a gateway in the IoT SiteWise console, all of your OPC-UA sources are stored in one capability configuration. To list all capability configurations for a gateway, use DescribeGateway (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeGateway.html).
#
# GET /20200301/gateways/{gatewayId}/capability/{capabilityNamespace}
# operationId: DescribeGatewayCapabilityConfiguration
export def "20200301-gateways-capability get-configuration" [
  gateway_id: string
  capability_namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<gatewayId: record, capabilityNamespace: record, capabilityConfiguration: record, capabilitySyncStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gateway_id: (encode-path-segment $gateway_id), capability_namespace: (encode-path-segment $capability_namespace)} | format pattern "/20200301/gateways/{gateway_id}/capability/{capability_namespace}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the current IoT SiteWise logging options.
#
# GET /logging
# operationId: DescribeLoggingOptions
export def "logging get-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<loggingOptions: record<level: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/logging")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets logging options for IoT SiteWise.
#
# PUT /logging
# operationId: PutLoggingOptions
# --loggingOptions shape: {level?: any}
export def "logging update-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  logging_options: record # Contains logging options. — shape: {level?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/logging")
  let req_body = {"loggingOptions": $logging_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves information about the storage configuration for IoT SiteWise.
#
# GET /configuration/account/storage
# operationId: DescribeStorageConfiguration
export def "configuration-account-storage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<storageType: record, multiLayerStorage: record<customerManagedS3Storage: record<s3ResourceArn: record, roleArn: record>>, disassociatedDataStorage: record, retentionPeriod: record<numberOfDays: record, unlimited: record>, configurationStatus: record<state: record, error: record<code: record, message: record>>, lastUpdateDate: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration/account/storage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configures storage settings for IoT SiteWise.
#
# POST /configuration/account/storage
# operationId: PutStorageConfiguration
# --multiLayerStorage shape: {customerManagedS3Storage?: any}
# --retentionPeriod shape: {numberOfDays?: any, unlimited?: any}
export def "configuration-account-storage update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  storage_type: string@storage-type-completer # The storage tier that you specified for your data. The storageType parameter can be one of the following values: SITEWISE_DEFAULT_STORAGE – IoT SiteWise saves your data into the hot tier. The hot tier is a service-managed database. MULTI_LAYER_STORAGE – IoT SiteWise saves your data in both the cold tier and the hot tier. The cold tier is a customer-managed Amazon S3 bucket.
  --multi-layer-storage: record # Contains information about the storage destination. — shape: {customerManagedS3Storage?: any}
  --disassociated-data-storage: string@disassociated-data-storage-completer # Contains the storage configuration for time series (data streams) that aren't associated with asset properties. The disassociatedDataStorage can be one of the following values: ENABLED – IoT SiteWise accepts time series that aren't associated with asset properties. After the disassociatedDataStorage is enabled, you can't disable it. DISABLED – IoT SiteWise doesn't accept time series (data streams) that aren't associated with asset properties. For more information, see Data streams (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/data-streams.html) in the IoT SiteWise User Guide.
  --retention-period: record # How many days your data is kept in the hot tier. By default, your data is kept indefinitely in the hot tier. — shape: {numberOfDays?: any, unlimited?: any}
]: any -> record<storageType: record, multiLayerStorage: record<customerManagedS3Storage: record<s3ResourceArn: record, roleArn: record>>, disassociatedDataStorage: record, retentionPeriod: record<numberOfDays: record, unlimited: record>, configurationStatus: record<state: record, error: record<code: record, message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration/account/storage")
  let req_body = {"storageType": $storage_type, "multiLayerStorage": $multi_layer_storage, "disassociatedDataStorage": $disassociated_data_storage, "retentionPeriod": $retention_period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves information about a time series (data stream). To identify a time series, do one of the following: If the time series isn't associated with an asset property, specify the alias of the time series. If the time series is associated with an asset property, specify one of the following: The alias of the time series. The assetId and propertyId that identifies the asset property.
#
# GET /timeseries/describe/
# operationId: DescribeTimeSeries
export def "timeseries-describe get-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string # The alias that identifies the time series.
  --asset-id: string # The ID of the asset in which the asset property was created.
  --property-id: string # The ID of the asset property.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetId: record, propertyId: record, alias: record, timeSeriesId: record, dataType: record, dataTypeSpec: record, timeSeriesCreationDate: record, timeSeriesLastUpdateDate: record, timeSeriesArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alias" $alias "scalar") (serialize-qp "assetId" $asset_id "scalar") (serialize-qp "propertyId" $property_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/describe/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disassociates a child asset from the given parent asset through a hierarchy defined in the parent asset's model.
#
# POST /assets/{assetId}/disassociate
# operationId: DisassociateAssets
export def "assets-disassociate create" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  hierarchy_id: string # The ID of a hierarchy in the parent asset's model. Hierarchies allow different groupings of assets to be formed that all come from the same asset model. You can use the hierarchy ID to identify the correct asset to disassociate. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide.
  child_asset_id: string # The ID of the child asset to disassociate.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/assets/{asset_id}/disassociate"))
  let req_body = {"hierarchyId": $hierarchy_id, "childAssetId": $child_asset_id, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disassociates a time series (data stream) from an asset property.
#
# POST /timeseries/disassociate/#alias&assetId&propertyId
# operationId: DisassociateTimeSeriesFromAssetProperty
export def "timeseries-disassociate-aliasasset-idproperty-id create-time-series-from-asset-property" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string # The alias that identifies the time series.
  --asset-id: string # The ID of the asset in which the asset property was created.
  --property-id: string # The ID of the asset property.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alias" $alias "scalar") (serialize-qp "assetId" $asset_id "scalar") (serialize-qp "propertyId" $property_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/disassociate/#alias&assetId&propertyId" $qp)
  let req_body = {"clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets aggregated values for an asset property. For more information, see Querying aggregates (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#aggregates) in the IoT SiteWise User Guide. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html).
#
# GET /properties/aggregates#aggregateTypes&resolution&startDate&endDate
# operationId: GetAssetPropertyAggregates
export def "properties-aggregatesaggregate-typesresolutionstart-dateend-date get-asset-property-aggregates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The ID of the asset.
  --property-id: string # The ID of the asset property.
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide.
  --aggregate-types: list # The data aggregating function.
  --resolution: string # The time interval over which to aggregate data.
  --qualities: list # The quality by which to filter asset data.
  --start-date: string # The exclusive start of the range from which to query historical data, expressed in seconds in Unix epoch time. (format: date-time)
  --end-date: string # The inclusive end of the range from which to query historical data, expressed in seconds in Unix epoch time. (format: date-time)
  --time-ordering: string@time-ordering-completer # The chronological sorting order of the requested information. Default: ASCENDING
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 100
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<aggregatedValues: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assetId" $asset_id "scalar") (serialize-qp "propertyId" $property_id "scalar") (serialize-qp "propertyAlias" $property_alias "scalar") (serialize-qp "aggregateTypes" $aggregate_types "multi") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "qualities" $qualities "multi") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "timeOrdering" $time_ordering "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/properties/aggregates#aggregateTypes&resolution&startDate&endDate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an asset property's current value. For more information, see Querying current values (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#current-values) in the IoT SiteWise User Guide. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html).
#
# GET /properties/latest
# operationId: GetAssetPropertyValue
export def "properties-latest get-asset-property-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The ID of the asset.
  --property-id: string # The ID of the asset property.
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<propertyValue: record<value: record<stringValue: record, integerValue: record, doubleValue: record, booleanValue: record>, timestamp: record<timeInSeconds: record, offsetInNanos: record>, quality: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assetId" $asset_id "scalar") (serialize-qp "propertyId" $property_id "scalar") (serialize-qp "propertyAlias" $property_alias "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/properties/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the history of an asset property's values. For more information, see Querying historical values (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#historical-values) in the IoT SiteWise User Guide. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html).
#
# GET /properties/history
# operationId: GetAssetPropertyValueHistory
export def "properties-history get-asset-property-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The ID of the asset.
  --property-id: string # The ID of the asset property.
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide.
  --start-date: string # The exclusive start of the range from which to query historical data, expressed in seconds in Unix epoch time. (format: date-time)
  --end-date: string # The inclusive end of the range from which to query historical data, expressed in seconds in Unix epoch time. (format: date-time)
  --qualities: list # The quality by which to filter asset data.
  --time-ordering: string@time-ordering-completer # The chronological sorting order of the requested information. Default: ASCENDING
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 100
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetPropertyValueHistory: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assetId" $asset_id "scalar") (serialize-qp "propertyId" $property_id "scalar") (serialize-qp "propertyAlias" $property_alias "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "qualities" $qualities "multi") (serialize-qp "timeOrdering" $time_ordering "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/properties/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get interpolated values for an asset property for a specified time interval, during a period of time. If your time series is missing data points during the specified time interval, you can use interpolation to estimate the missing data. For example, you can use this operation to return the interpolated temperature values for a wind turbine every 24 hours over a duration of 7 days. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html).
#
# GET /properties/interpolated#startTimeInSeconds&endTimeInSeconds&quality&intervalInSeconds&type
# operationId: GetInterpolatedAssetPropertyValues
export def "properties-interpolatedstart-time-in-secondsend-time-in-secondsqualityinterval-in-secondstype get-interpolated-asset-property-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The ID of the asset.
  --property-id: string # The ID of the asset property.
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide.
  --start-time-in-seconds: int # The exclusive start of the range from which to interpolate data, expressed in seconds in Unix epoch time.
  --start-time-offset-in-nanos: int # The nanosecond offset converted from startTimeInSeconds.
  --end-time-in-seconds: int # The inclusive end of the range from which to interpolate data, expressed in seconds in Unix epoch time.
  --end-time-offset-in-nanos: int # The nanosecond offset converted from endTimeInSeconds.
  --quality: string@quality-completer # The quality of the asset property value. You can use this parameter as a filter to choose only the asset property values that have a specific quality.
  --interval-in-seconds: int # The time interval in seconds over which to interpolate data. Each interval starts when the previous one ends.
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. If not specified, the default value is 10.
  --type: string # The interpolation type. Valid values: LINEAR_INTERPOLATION | LOCF_INTERPOLATION LINEAR_INTERPOLATION – Estimates missing data using linear interpolation (https://en.wikipedia.org/wiki/Linear_interpolation). For example, you can use this operation to return the interpolated temperature values for a wind turbine every 24 hours over a duration of 7 days. If the interpolation starts July 1, 2021, at 9 AM, IoT SiteWise returns the first interpolated value on July 2, 2021, at 9 AM, the second interpolated value on July 3, 2021, at 9 AM, and so on. LOCF_INTERPOLATION – Estimates missing data using last observation carried forward interpolation If no data point is found for an interval, IoT SiteWise returns the last observed data point for the previous interval and carries forward this interpolated value until a new data point is found. For example, you can get the state of an on-off valve every 24 hours over a duration of 7 days. If the interpolation starts July 1, 2021, at 9 AM, IoT SiteWise returns the last observed data point between July 1, 2021, at 9 AM and July 2, 2021, at 9 AM as the first interpolated value. If a data point isn't found after 9 AM on July 2, 2021, IoT SiteWise uses the same interpolated value for the rest of the days.
  --interval-window-in-seconds: int # The query interval for the window, in seconds. IoT SiteWise computes each interpolated value by using data points from the timestamp of each interval, minus the window to the timestamp of each interval plus the window. If not specified, the window ranges between the start time minus the interval and the end time plus the interval. If you specify a value for the intervalWindowInSeconds parameter, the value for the type parameter must be LINEAR_INTERPOLATION. If a data point isn't found during the specified query window, IoT SiteWise won't return an interpolated value for the interval. This indicates that there's a gap in the ingested data points. For example, you can get the interpolated temperature values for a wind turbine every 24 hours over a duration of 7 days. If the interpolation starts on July 1, 2021, at 9 AM with a window of 2 hours, IoT SiteWise uses the data points from 7 AM (9 AM minus 2 hours) to 11 AM (9 AM plus 2 hours) on July 2, 2021 to compute the first interpolated value. Next, IoT SiteWise uses the data points from 7 AM (9 AM minus 2 hours) to 11 AM (9 AM plus 2 hours) on July 3, 2021 to compute the second interpolated value, and so on.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<interpolatedAssetPropertyValues: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assetId" $asset_id "scalar") (serialize-qp "propertyId" $property_id "scalar") (serialize-qp "propertyAlias" $property_alias "scalar") (serialize-qp "startTimeInSeconds" $start_time_in_seconds "scalar") (serialize-qp "startTimeOffsetInNanos" $start_time_offset_in_nanos "scalar") (serialize-qp "endTimeInSeconds" $end_time_in_seconds "scalar") (serialize-qp "endTimeOffsetInNanos" $end_time_offset_in_nanos "scalar") (serialize-qp "quality" $quality "scalar") (serialize-qp "intervalInSeconds" $interval_in_seconds "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "intervalWindowInSeconds" $interval_window_in_seconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/properties/interpolated#startTimeInSeconds&endTimeInSeconds&quality&intervalInSeconds&type" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of properties associated with an asset model. If you update properties associated with the model before you finish listing all the properties, you need to start all over again.
#
# GET /asset-models/{assetModelId}/properties
# operationId: ListAssetModelProperties
export def "asset-models-properties list" [
  asset_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. If not specified, the default value is 50.
  --filter: string@filter-completer-2 # Filters the requested list of asset model properties. You can choose one of the following options: ALL – The list includes all asset model properties for a given asset model ID. BASE – The list includes only base asset model properties for a given asset model ID. Default: BASE
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetModelPropertySummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_model_id: (encode-path-segment $asset_model_id)} | format pattern "/asset-models/{asset_model_id}/properties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of properties associated with an asset. If you update properties associated with the model before you finish listing all the properties, you need to start all over again.
#
# GET /assets/{assetId}/properties
# operationId: ListAssetProperties
export def "assets-properties list" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. If not specified, the default value is 50.
  --filter: string@filter-completer-2 # Filters the requested list of asset properties. You can choose one of the following options: ALL – The list includes all asset properties for a given asset model ID. BASE – The list includes only base asset properties for a given asset model ID. Default: BASE
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetPropertySummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/assets/{asset_id}/properties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of asset relationships for an asset. You can use this operation to identify an asset's root asset and all associated assets between that asset and its root.
#
# GET /assets/{assetId}/assetRelationships#traversalType
# operationId: ListAssetRelationships
export def "assets-asset-relationshipstraversal-type list-relationships" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --traversal-type: string@traversal-type-completer # The type of traversal to use to identify asset relationships. Choose the following option: PATH_TO_ROOT – Identify the asset's parent assets up to the root asset. The asset that you specify in assetId is the first result in the list of assetRelationshipSummaries, and the root asset is the last result.
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetRelationshipSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "traversalType" $traversal_type "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/assets/{asset_id}/assetRelationships#traversalType") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of associated assets. You can use this operation to do the following: List child assets associated to a parent asset by a hierarchy that you specify. List an asset's parent asset.
#
# GET /assets/{assetId}/hierarchies
# operationId: ListAssociatedAssets
export def "assets-hierarchies list-associated" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hierarchy-id: string # The ID of the hierarchy by which child assets are associated to the asset. To find a hierarchy ID, use the DescribeAsset (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeAsset.html) or DescribeAssetModel (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeAssetModel.html) operations. This parameter is required if you choose CHILD for traversalDirection. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide.
  --traversal-direction: string@traversal-direction-completer # The direction to list associated assets. Choose one of the following options: CHILD – The list includes all child assets associated to the asset. The hierarchyId parameter is required if you choose CHILD. PARENT – The list includes the asset's parent asset. Default: CHILD
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hierarchyId" $hierarchy_id "scalar") (serialize-qp "traversalDirection" $traversal_direction "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/assets/{asset_id}/hierarchies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of dashboards for an IoT SiteWise Monitor project.
#
# GET /dashboards#projectId
# operationId: ListDashboards
export def "dashboardsproject-id list-dashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string # The ID of the project.
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<dashboardSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboards#projectId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of assets associated with an IoT SiteWise Monitor project.
#
# GET /projects/{projectId}/assets
# operationId: ListProjectAssets
export def "projects-assets list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<assetIds: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/assets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of projects for an IoT SiteWise Monitor portal.
#
# GET /projects#portalId
# operationId: ListProjects
export def "projectsportal-id list-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --portal-id: string # The ID of the portal.
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<projectSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "portalId" $portal_id "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects#portalId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the list of tags for an IoT SiteWise resource.
#
# GET /tags#resourceArn
# operationId: ListTagsForResource
export def "tagsresource-arn list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceArn" $resource_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags#resourceArn" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds tags to an IoT SiteWise resource. If a tag already exists for the resource, this operation updates the tag's value.
#
# POST /tags#resourceArn
# operationId: TagResource
export def "tagsresource-arn tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource to tag.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # A list of key-value pairs that contain metadata for the resource. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceArn" $resource_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags#resourceArn" $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a paginated list of time series (data streams).
#
# GET /timeseries/
# operationId: ListTimeSeries
export def "timeseries list-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request.
  --asset-id: string # The ID of the asset in which the asset property was created.
  --alias-prefix: string # The alias prefix of the time series.
  --time-series-type: string@time-series-type-completer # The type of the time series. The time series type can be one of the following values: ASSOCIATED – The time series is associated with an asset property. DISASSOCIATED – The time series isn't associated with any asset property.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TimeSeriesSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "assetId" $asset_id "scalar") (serialize-qp "aliasPrefix" $alias_prefix "scalar") (serialize-qp "timeSeriesType" $time_series_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a tag from an IoT SiteWise resource.
#
# DELETE /tags#resourceArn&tagKeys
# operationId: UntagResource
export def "tagsresource-arntag-keys untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource to untag.
  --tag-keys: list # A list of keys for tags to remove from the resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceArn" $resource_arn "scalar") (serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/tags#resourceArn&tagKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a gateway capability configuration or defines a new capability configuration. Each gateway capability defines data sources for a gateway. A capability configuration can contain multiple data source configurations. If you define OPC-UA sources for a gateway in the IoT SiteWise console, all of your OPC-UA sources are stored in one capability configuration. To list all capability configurations for a gateway, use DescribeGateway (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeGateway.html).
#
# POST /20200301/gateways/{gatewayId}/capability
# operationId: UpdateGatewayCapabilityConfiguration
export def "20200301-gateways-capability update-configuration" [
  gateway_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  capability_namespace: string # The namespace of the gateway capability configuration to be updated. For example, if you configure OPC-UA sources from the IoT SiteWise console, your OPC-UA capability configuration has the namespace iotsitewise:opcuacollector:version, where version is a number such as 1.
  capability_configuration: string # The JSON document that defines the configuration for the gateway capability. For more information, see Configuring data sources (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/configure-sources.html#configure-source-cli) in the IoT SiteWise User Guide.
]: any -> record<capabilityNamespace: record, capabilitySyncStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({gateway_id: (encode-path-segment $gateway_id)} | format pattern "/20200301/gateways/{gateway_id}/capability"))
  let req_body = {"capabilityNamespace": $capability_namespace, "capabilityConfiguration": $capability_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
